package com.cslauncher.hosting

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.concurrent.Executors

/**
 * Native skeleton for real Minecraft server hosting on Android.
 *
 * MethodChannel: com.cslauncher.hosting/server
 * EventChannel:  com.cslauncher.hosting/console
 *
 * Flutter calls:
 *  - startServer(serverId, jarPath, maxRamMb, port, workingDir)
 *  - stopServer(serverId)
 *  - sendCommand(serverId, command)
 *  - isRunning(serverId)
 *
 * Console lines are pushed on the EventChannel.
 *
 * TODO before production:
 *  - Bundle or download a JRE (e.g. Liberica / Termux proot)
 *  - Run ProcessBuilder with java -Xmx... -jar server.jar nogui
 *  - Start ForegroundService so process survives background
 *  - Start bore client for public tunnel
 *  - Battery optimization exemption UX
 */
class ServerHostPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var appContext: Context

    private val processes = mutableMapOf<String, Process>()
    private val executor = Executors.newCachedThreadPool()

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
            "startServer" -> {
                val serverId = call.argument<String>("serverId") ?: return result.error("ARG", "serverId required", null)
                val jarPath = call.argument<String>("jarPath") ?: return result.error("ARG", "jarPath required", null)
                val maxRamMb = call.argument<Int>("maxRamMb") ?: 1024
                val port = call.argument<Int>("port") ?: 25565
                val workingDir = call.argument<String>("workingDir") ?: return result.error("ARG", "workingDir required", null)

                // Skeleton: log intent; real impl starts ProcessBuilder
                pushLog(serverId, "INFO [Native] startServer requested")
                pushLog(serverId, "INFO [Native] jar=$jarPath ram=${maxRamMb}MB port=$port")
                pushLog(serverId, "INFO [Native] workDir=$workingDir")
                pushLog(serverId, "WARN [Native] JRE not embedded yet — simulation only on device")

                // Placeholder so Flutter can treat as "started" in hybrid mode
                result.success(mapOf(
                    "ok" to true,
                    "mode" to "skeleton",
                    "message" to "Native skeleton active. Embed JRE + ProcessBuilder next."
                ))
            }

            "stopServer" -> {
                val serverId = call.argument<String>("serverId") ?: return result.error("ARG", "serverId required", null)
                processes[serverId]?.destroy()
                processes.remove(serverId)
                pushLog(serverId, "INFO [Native] stopServer")
                result.success(true)
            }

            "sendCommand" -> {
                val serverId = call.argument<String>("serverId") ?: return result.error("ARG", "serverId required", null)
                val command = call.argument<String>("command") ?: return result.error("ARG", "command required", null)
                val proc = processes[serverId]
                if (proc == null) {
                    pushLog(serverId, "WARN [Native] no process for $serverId (skeleton)")
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
                val serverId = call.argument<String>("serverId") ?: return result.error("ARG", "serverId required", null)
                val dir = File(appContext.filesDir, "servers/$serverId")
                if (!dir.exists()) dir.mkdirs()
                result.success(dir.absolutePath)
            }

            else -> result.notImplemented()
        }
    }

    private fun pushLog(serverId: String, line: String) {
        eventSink?.success(mapOf(
            "serverId" to serverId,
            "line" to line
        ))
    }

    private fun stopAll() {
        processes.values.forEach { it.destroy() }
        processes.clear()
    }

    /**
     * Example of how real start will look (not called until JRE is ready):
     *
     * val cmd = listOf(
     *   javaBinary,
     *   "-Xms512M",
     *   "-Xmx${maxRamMb}M",
     *   "-jar", jarPath,
     *   "nogui"
     * )
     * val pb = ProcessBuilder(cmd)
     * pb.directory(File(workingDir))
     * pb.redirectErrorStream(true)
     * val process = pb.start()
     * processes[serverId] = process
     * executor.execute { readStdout(serverId, process) }
     * // also start ForegroundService + bore tunnel
     */
}
