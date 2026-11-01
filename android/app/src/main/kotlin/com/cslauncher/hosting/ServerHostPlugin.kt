package com.cslauncher.hosting

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.regex.Pattern

/**
 * Native bridge for CS LAUNCHER:
 * - startTunnel runs bore client to bore.pub
 * - Parses listening at host:port
 * Binary: filesDir/tools/bore — see docs/BORE_CONNECT.md
 */
class ServerHostPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var appContext: Context

    private val processes = ConcurrentHashMap<String, Process>()
    private val boreProcesses = ConcurrentHashMap<String, Process>()
    private val executor = Executors.newCachedThreadPool()

    private val addressPattern = Pattern.compile(
        "listening at\\s+([\\w.\\-]+):(\\d+)",
        Pattern.CASE_INSENSITIVE
    )

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.cslauncher.hosting/server")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.cslauncher.hosting/console")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopAll()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startTunnel" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                val localPort = call.argument<Int>("localPort") ?: 25565
                val toHost = call.argument<String>("toHost") ?: "bore.pub"
                val secret = call.argument<String>("secret")

                executor.execute {
                    try {
                        val addr = startBore(serverId, localPort, toHost, secret)
                        android.os.Handler(appContext.mainLooper).post {
                            if (addr != null) {
                                result.success(
                                    mapOf(
                                        "ok" to true,
                                        "publicAddress" to addr,
                                        "mode" to "bore"
                                    )
                                )
                            } else {
                                result.success(
                                    mapOf(
                                        "ok" to false,
                                        "mode" to "missing_binary",
                                        "message" to "bore binary not found at files/tools/bore"
                                    )
                                )
                            }
                        }
                    } catch (e: Exception) {
                        android.os.Handler(appContext.mainLooper).post {
                            result.success(
                                mapOf(
                                    "ok" to false,
                                    "mode" to "error",
                                    "message" to (e.message ?: "tunnel failed")
                                )
                            )
                        }
                    }
                }
            }

            "stopTunnel" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                stopBore(serverId)
                pushLog(serverId, "INFO [Tunnel] Closed")
                result.success(true)
            }

            "hasBoreBinary" -> result.success(findBoreBinary() != null)

            "startServer" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                pushLog(serverId, "INFO [Native] startServer skeleton")
                result.success(mapOf("ok" to true, "mode" to "skeleton"))
            }

            "stopServer" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                processes[serverId]?.destroy()
                processes.remove(serverId)
                stopBore(serverId)
                result.success(true)
            }

            "sendCommand" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                val command = call.argument<String>("command")
                    ?: return result.error("ARG", "command", null)
                val proc = processes[serverId]
                if (proc == null) {
                    result.success(false)
                    return
                }
                try {
                    proc.outputStream.write("$command\n".toByteArray())
                    proc.outputStream.flush()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("IO", e.message, null)
                }
            }

            "isRunning" -> {
                val serverId = call.argument<String>("serverId")
                result.success(serverId != null && processes.containsKey(serverId))
            }

            "getServerDir" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                val dir = File(appContext.filesDir, "servers/$serverId")
                if (!dir.exists()) dir.mkdirs()
                result.success(dir.absolutePath)
            }

            else -> result.notImplemented()
        }
    }

    private fun findBoreBinary(): File? {
        val tools = File(appContext.filesDir, "tools/bore")
        if (tools.exists()) {
            tools.setExecutable(true)
            if (tools.canExecute()) return tools
        }
        return null
    }

    private fun startBore(
        serverId: String,
        localPort: Int,
        toHost: String,
        secret: String?
    ): String? {
        stopBore(serverId)
        val binary = findBoreBinary()
        if (binary == null) {
            pushLog(serverId, "WARN [Tunnel] bore binary not found")
            pushLog(serverId, "INFO [Tunnel] See docs/BORE_CONNECT.md")
            return null
        }

        val cmd = mutableListOf(
            binary.absolutePath,
            "local",
            localPort.toString(),
            "--to",
            toHost
        )
        if (!secret.isNullOrBlank()) {
            cmd.add("--secret")
            cmd.add(secret)
        }

        pushLog(serverId, "INFO [Tunnel] Starting bore → $toHost")

        val pb = ProcessBuilder(cmd)
        pb.redirectErrorStream(true)
        val proc = pb.start()
        boreProcesses[serverId] = proc

        var publicAddress: String? = null
        val deadline = System.currentTimeMillis() + 15000L
        val reader = BufferedReader(InputStreamReader(proc.inputStream))

        while (System.currentTimeMillis() < deadline) {
            val line = reader.readLine() ?: break
            pushLog(serverId, "INFO [bore] $line")
            val m = addressPattern.matcher(line)
            if (m.find()) {
                publicAddress = m.group(1) + ":" + m.group(2)
                pushLog(serverId, "INFO [Tunnel] Public: $publicAddress")
                break
            }
        }

        executor.execute {
            try {
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    pushLog(serverId, "INFO [bore] $line")
                }
            } catch (_: Exception) {
            }
        }

        return publicAddress
    }

    private fun stopBore(serverId: String) {
        boreProcesses[serverId]?.destroy()
        boreProcesses.remove(serverId)
    }

    private fun pushLog(serverId: String, line: String) {
        val sink = eventSink ?: return
        android.os.Handler(appContext.mainLooper).post {
            sink.success(mapOf("serverId" to serverId, "line" to line))
        }
    }

    private fun stopAll() {
        processes.values.forEach { it.destroy() }
        processes.clear()
        boreProcesses.values.forEach { it.destroy() }
        boreProcesses.clear()
    }
}
