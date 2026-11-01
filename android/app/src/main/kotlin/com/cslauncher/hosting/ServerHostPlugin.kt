package com.cslauncher.hosting

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.regex.Pattern

/**
 * MineServe-style host plugin:
 * - Auto bore download + bore.pub tunnel
 * - prepareServer: Paper jar URL download + eula.txt
 * - startServer: java -jar if JRE found under files/runtime
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

    private val boreVersion = "0.5.2"

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
            "prepareServer" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                val jarUrl = call.argument<String>("jarUrl")
                val version = call.argument<String>("version") ?: "1.21.1"

                executor.execute {
                    try {
                        val dir = serverDir(serverId)
                        val jar = File(dir, "server.jar")
                        if (!jar.exists() || jar.length() < 1000) {
                            if (jarUrl.isNullOrBlank()) {
                                throw Exception("jarUrl required for first download")
                            }
                            pushLog(serverId, "INFO [Setup] Downloading Paper $version...")
                            downloadFile(jarUrl, jar)
                            pushLog(serverId, "INFO [Setup] server.jar ready (${jar.length() / 1024 / 1024} MB)")
                        } else {
                            pushLog(serverId, "INFO [Setup] server.jar already present")
                        }

                        val eula = File(dir, "eula.txt")
                        if (!eula.exists()) {
                            eula.writeText("eula=true\n")
                            pushLog(serverId, "INFO [Setup] eula.txt accepted")
                        }

                        // minimal server.properties
                        val props = File(dir, "server.properties")
                        if (!props.exists()) {
                            props.writeText(
                                "server-port=25565\nonline-mode=true\nmotd=CS LAUNCHER\nmax-players=20\n"
                            )
                        }

                        android.os.Handler(appContext.mainLooper).post {
                            result.success(
                                mapOf(
                                    "ok" to true,
                                    "serverDir" to dir.absolutePath,
                                    "jarPath" to jar.absolutePath
                                )
                            )
                        }
                    } catch (e: Exception) {
                        pushLog(serverId, "ERROR [Setup] ${e.message}")
                        android.os.Handler(appContext.mainLooper).post {
                            result.success(
                                mapOf("ok" to false, "message" to (e.message ?: "prepare failed"))
                            )
                        }
                    }
                }
            }

            "startTunnel" -> {
                val serverId = call.argument<String>("serverId")
                    ?: return result.error("ARG", "serverId", null)
                val localPort = call.argument<Int>("localPort") ?: 25565
                val toHost = call.argument<String>("toHost") ?: "bore.pub"
                val secret = call.argument<String>("secret")

                executor.execute {
                    try {
                        ensureBoreBinary(serverId)
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
                                        "mode" to "tunnel_failed",
                                        "message" to "no public address"
                                    )
                                )
                            }
                        }
                    } catch (e: Exception) {
                        pushLog(serverId, "ERROR [Tunnel] ${e.message}")
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
                val maxRamMb = call.argument<Int>("maxRamMb") ?: 1024
                val jarPath = call.argument<String>("jarPath")
                val workingDir = call.argument<String>("workingDir")

                executor.execute {
                    try {
                        val dir = if (workingDir != null) File(workingDir) else serverDir(serverId)
                        val jar = if (jarPath != null) File(jarPath) else File(dir, "server.jar")
                        if (!jar.exists()) {
                            android.os.Handler(appContext.mainLooper).post {
                                result.success(
                                    mapOf(
                                        "ok" to false,
                                        "mode" to "no_jar",
                                        "message" to "server.jar missing — call prepareServer first"
                                    )
                                )
                            }
                            return@execute
                        }

                        val javaBin = findJavaBinary()
                        if (javaBin == null) {
                            pushLog(serverId, "WARN [Native] No JRE in files/runtime — install OpenJDK (MineServe Phase B)")
                            android.os.Handler(appContext.mainLooper).post {
                                result.success(
                                    mapOf(
                                        "ok" to false,
                                        "mode" to "no_jre",
                                        "message" to "Place JRE at files/runtime/jdk/bin/java",
                                        "serverDir" to dir.absolutePath,
                                        "jarPath" to jar.absolutePath
                                    )
                                )
                            }
                            return@execute
                        }

                        // stop old
                        processes[serverId]?.destroy()

                        val cmd = listOf(
                            javaBin.absolutePath,
                            "-Xms256M",
                            "-Xmx${maxRamMb}M",
                            "-jar",
                            jar.absolutePath,
                            "nogui"
                        )
                        pushLog(serverId, "INFO [Native] ${cmd.joinToString(" ")}")

                        val pb = ProcessBuilder(cmd)
                        pb.directory(dir)
                        pb.redirectErrorStream(true)
                        val proc = pb.start()
                        processes[serverId] = proc

                        executor.execute { streamProcess(serverId, proc) }

                        android.os.Handler(appContext.mainLooper).post {
                            result.success(
                                mapOf(
                                    "ok" to true,
                                    "mode" to "java",
                                    "serverDir" to dir.absolutePath
                                )
                            )
                        }
                    } catch (e: Exception) {
                        pushLog(serverId, "ERROR [Native] ${e.message}")
                        android.os.Handler(appContext.mainLooper).post {
                            result.success(
                                mapOf("ok" to false, "mode" to "error", "message" to e.message)
                            )
                        }
                    }
                }
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
                result.success(serverDir(serverId).absolutePath)
            }

            "hasJava" -> result.success(findJavaBinary() != null)

            else -> result.notImplemented()
        }
    }

    private fun serverDir(serverId: String): File {
        val dir = File(appContext.filesDir, "servers/$serverId")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun toolsDir(): File {
        val d = File(appContext.filesDir, "tools")
        if (!d.exists()) d.mkdirs()
        return d
    }

    /** files/runtime/jdk/bin/java or runtime/bin/java */
    private fun findJavaBinary(): File? {
        val candidates = listOf(
            File(appContext.filesDir, "runtime/jdk/bin/java"),
            File(appContext.filesDir, "runtime/bin/java"),
            File(appContext.filesDir, "runtime/java")
        )
        for (f in candidates) {
            if (f.exists()) {
                f.setExecutable(true)
                if (f.canExecute()) return f
            }
        }
        return null
    }

    private fun findBoreBinary(): File? {
        val tools = File(toolsDir(), "bore")
        if (tools.exists()) {
            tools.setExecutable(true)
            if (tools.canExecute()) return tools
        }
        return null
    }

    private fun ensureBoreBinary(serverId: String) {
        if (findBoreBinary() != null) {
            pushLog(serverId, "INFO [Tunnel] bore binary OK")
            return
        }

        val abi = when {
            Build.SUPPORTED_ABIS.contains("arm64-v8a") -> "aarch64-unknown-linux-musl"
            Build.SUPPORTED_ABIS.contains("x86_64") -> "x86_64-unknown-linux-musl"
            else -> "aarch64-unknown-linux-musl"
        }

        val asset = "bore-v$boreVersion-$abi.tar.gz"
        val url =
            "https://github.com/ekzhang/bore/releases/download/v$boreVersion/$asset"

        pushLog(serverId, "INFO [Tunnel] Downloading bore...")
        val tarGz = File(toolsDir(), asset)
        downloadFile(url, tarGz)

        ProcessBuilder(
            "tar", "-xzf", tarGz.absolutePath, "-C", toolsDir().absolutePath
        ).redirectErrorStream(true).start().waitFor()

        val binary = File(toolsDir(), "bore")
        if (!binary.exists()) throw Exception("bore extract failed")
        binary.setExecutable(true)
        tarGz.delete()
        pushLog(serverId, "INFO [Tunnel] bore installed")
    }

    private fun downloadFile(urlStr: String, out: File) {
        val conn = URL(urlStr).openConnection() as HttpURLConnection
        conn.connectTimeout = 60000
        conn.readTimeout = 300000
        conn.instanceFollowRedirects = true
        conn.setRequestProperty("User-Agent", "CS-LAUNCHER-HOSTING")
        conn.connect()
        if (conn.responseCode !in 200..299) {
            throw Exception("Download failed HTTP ${conn.responseCode}")
        }
        conn.inputStream.use { input ->
            FileOutputStream(out).use { output -> input.copyTo(output) }
        }
        conn.disconnect()
    }

    private fun startBore(
        serverId: String,
        localPort: Int,
        toHost: String,
        secret: String?
    ): String? {
        stopBore(serverId)
        val binary = findBoreBinary() ?: return null

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
        val deadline = System.currentTimeMillis() + 20000L
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

    private fun streamProcess(serverId: String, proc: Process) {
        try {
            val reader = BufferedReader(InputStreamReader(proc.inputStream))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                pushLog(serverId, line ?: "")
            }
        } catch (_: Exception) {
        }
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
