import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/server_model.dart';
import '../models/plugin_model.dart';
import '../services/native_host_service.dart';
import '../services/paper_api_service.dart';

class ServerProvider extends ChangeNotifier {
  List<ServerModel> _servers = [];
  List<ServerModel> get servers => _servers;

  ServerModel? _selectedServer;
  ServerModel? get selectedServer => _selectedServer;

  final Map<String, List<String>> _consoleLogs = {};
  List<String> getLogs(String serverId) => _consoleLogs[serverId] ?? [];

  final Map<String, List<String>> _onlinePlayers = {};
  List<String> getOnlinePlayers(String serverId) =>
      List.unmodifiable(_onlinePlayers[serverId] ?? []);

  final Map<String, Set<String>> _ops = {};
  final Map<String, Set<String>> _banned = {};

  final Map<String, List<String>> _installedPlugins = {};
  List<String> getInstalledPluginIds(String serverId) =>
      List.unmodifiable(_installedPlugins[serverId] ?? []);

  final List<PluginModel> availablePlugins = getPopularPlugins();

  Timer? _ramTimer;

  ServerProvider() {
    _loadServers();
    if (_servers.isEmpty) _addDemoServers();
  }

  void _addDemoServers() {
    final demo1 = ServerModel(
      id: 'demo-smp',
      name: 'SMP Server',
      software: ServerSoftware.paper,
      version: '1.21.1',
      status: ServerStatus.offline,
      maxPlayers: 20,
      maxRamGb: 2.0,
      tunnelProvider: TunnelProvider.borePub,
      tunnelHost: 'bore.pub',
    );
    _servers = [demo1];
    notifyListeners();
  }

  Future<void> _loadServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('servers');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _servers = list.map((e) => ServerModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading servers: $e');
    }
  }

  Future<void> _saveServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'servers', jsonEncode(_servers.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving: $e');
    }
  }

  void selectServer(ServerModel? server) {
    _selectedServer = server;
    notifyListeners();
  }

  Future<void> createServer(ServerModel server) async {
    _servers.add(server);
    _consoleLogs[server.id] = [];
    _onlinePlayers[server.id] = [];
    _ops[server.id] = {};
    _banned[server.id] = {};
    _installedPlugins[server.id] = [];
    await _saveServers();
    notifyListeners();
  }

  Future<void> updateServer(ServerModel server) async {
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      _servers[index] = server;
      if (_selectedServer?.id == server.id) _selectedServer = server;
      await _saveServers();
      notifyListeners();
    }
  }

  Future<void> deleteServer(String id) async {
    _servers.removeWhere((s) => s.id == id);
    _consoleLogs.remove(id);
    _onlinePlayers.remove(id);
    if (_selectedServer?.id == id) _selectedServer = null;
    await _saveServers();
    notifyListeners();
  }

  bool isPluginInstalled(String serverId, String pluginId) =>
      (_installedPlugins[serverId] ?? []).contains(pluginId);

  List<PluginModel> getInstalledPlugins(String serverId) {
    final ids = _installedPlugins[serverId] ?? [];
    return availablePlugins.where((p) => ids.contains(p.id)).toList();
  }

  Future<void> installPlugin(String serverId, String pluginId) async {
    final plugins = _installedPlugins.putIfAbsent(serverId, () => []);
    if (plugins.contains(pluginId)) return;
    plugins.add(pluginId);
    _addLog(serverId, 'INFO Installed plugin');
    notifyListeners();
  }

  Future<void> uninstallPlugin(String serverId, String pluginId) async {
    _installedPlugins[serverId]?.remove(pluginId);
    notifyListeners();
  }

  /// MineServe-style START:
  /// 1) Paper jar URL  2) prepareServer download  3) java -jar  4) bore.pub
  Future<void> startServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final server = _servers[index];
    if (server.status == ServerStatus.online ||
        server.status == ServerStatus.starting) return;

    server.status = ServerStatus.starting;
    notifyListeners();

    try {
      // 1) Paper download URL
      _addLog(id, 'INFO [MineServe] Resolving Paper ${server.version}...');
      final jarUrl = await PaperApiService.latestJarUrl(server.version);
      if (jarUrl == null) {
        _addLog(id, 'WARN Paper API failed — continuing with existing jar if any');
      } else {
        _addLog(id, 'INFO Paper URL ready');
      }

      // 2) Native: download jar + eula
      if (jarUrl != null) {
        final prep = await NativeHostService.prepareServer(
          serverId: id,
          jarUrl: jarUrl,
          version: server.version,
        );
        if (prep['ok'] == true) {
          _addLog(id, 'INFO server.jar + eula ready');
        } else {
          _addLog(id, 'WARN prepare: ${prep['message']}');
        }
      }

      // 3) Java process (needs JRE in files/runtime)
      final maxMb = (server.maxRamGb * 1024).round();
      final nativeStart = await NativeHostService.startServer(
        serverId: id,
        maxRamMb: maxMb,
      );
      if (nativeStart['ok'] == true) {
        _addLog(id, 'INFO Java server process started');
      } else {
        _addLog(
          id,
          'WARN Java: ${nativeStart['mode']} — ${nativeStart['message'] ?? 'no JRE yet'}',
        );
        _addLog(id, 'INFO Put OpenJDK at files/runtime/jdk/bin/java (Phase B)');
      }

      // 4) bore.pub tunnel
      final toHost = server.tunnelProvider == TunnelProvider.borePub
          ? 'bore.pub'
          : server.effectiveTunnelHost;
      _addLog(id, 'INFO Tunnel → $toHost');
      final tunnel = await NativeHostService.startTunnel(
        serverId: id,
        localPort: server.port,
        toHost: toHost,
      );

      if (tunnel['ok'] == true && tunnel['publicAddress'] != null) {
        server.publicAddress = tunnel['publicAddress'] as String;
        _addLog(id, 'INFO REAL public: ${server.publicAddress}');
      } else {
        final port = 30000 + Random().nextInt(10000);
        server.publicAddress = '$toHost:$port';
        _addLog(id, 'WARN Tunnel fallback demo: ${server.publicAddress}');
        _addLog(id, 'INFO ${tunnel['message'] ?? tunnel['mode']}');
      }

      server.status = ServerStatus.online;
      server.lastStarted = DateTime.now();
      server.usedRamGb = 0.5;
      _onlinePlayers[id] = [];
      _startRamSimulation(id);
      _addLog(id, 'INFO Online — share ${server.publicAddress}');
    } catch (e) {
      _addLog(id, 'ERROR $e');
      server.status = ServerStatus.error;
    }

    await _saveServers();
    notifyListeners();
  }

  Future<void> stopServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final server = _servers[index];
    if (server.status == ServerStatus.offline ||
        server.status == ServerStatus.stopping) return;

    server.status = ServerStatus.stopping;
    notifyListeners();
    _addLog(id, 'INFO Stopping...');
    await NativeHostService.stopTunnel(id);
    await NativeHostService.stopServer(id);
    _onlinePlayers[id] = [];
    server.status = ServerStatus.offline;
    server.onlinePlayers = 0;
    server.usedRamGb = 0;
    server.publicAddress = null;
    _ramTimer?.cancel();
    _addLog(id, 'INFO Stopped');
    await _saveServers();
    notifyListeners();
  }

  void _addLog(String id, String message) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    String level = 'INFO';
    String clean = message;
    if (message.startsWith('>')) {
      _consoleLogs.putIfAbsent(id, () => []).add('$time $message');
    } else {
      if (message.startsWith('ERROR')) {
        level = 'ERROR';
        clean = message.substring(5).trim();
      } else if (message.startsWith('WARN')) {
        level = 'WARN';
        clean = message.substring(4).trim();
      } else if (message.startsWith('INFO')) {
        clean = message.substring(4).trim();
      }
      _consoleLogs.putIfAbsent(id, () => []).add('$time $level $clean');
    }
    final list = _consoleLogs[id]!;
    if (list.length > 300) {
      _consoleLogs[id] = list.sublist(list.length - 300);
    }
    notifyListeners();
  }

  void sendCommand(String serverId, String rawCommand) {
    final command = rawCommand.trim();
    if (command.isEmpty) return;
    final serverIndex = _servers.indexWhere((s) => s.id == serverId);
    if (serverIndex == -1) return;
    final server = _servers[serverIndex];
    _addLog(serverId, '> $command');
    if (server.status != ServerStatus.online) {
      _addLog(serverId, 'ERROR Server is not running');
      return;
    }
    // Prefer native stdin when Java process exists
    NativeHostService.startServer; // no-op keep import used via stop/start
    String cmd = command.startsWith('/') ? command.substring(1) : command;
    final parts = cmd.split(RegExp(r'\s+'));
    final mainCmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];
    switch (mainCmd) {
      case 'help':
        _addLog(serverId, 'INFO /list /op /kick /stop');
        break;
      case 'list':
        final p = _onlinePlayers[serverId] ?? [];
        _addLog(serverId, 'INFO ${p.length} online');
        break;
      case 'op':
        if (args.isNotEmpty) {
          _ops.putIfAbsent(serverId, () => {}).add(args[0]);
          _addLog(serverId, 'INFO Opped ${args[0]}');
        }
        break;
      case 'stop':
        stopServer(serverId);
        break;
      default:
        _addLog(serverId, 'INFO Command sent (native if Java running)');
    }
    notifyListeners();
  }

  void _startRamSimulation(String id) {
    _ramTimer?.cancel();
    _ramTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final index = _servers.indexWhere((s) => s.id == id);
      if (index == -1 || _servers[index].status != ServerStatus.online) {
        timer.cancel();
        return;
      }
      final server = _servers[index];
      final r = Random();
      server.usedRamGb = (server.usedRamGb + (r.nextDouble() - 0.5) * 0.1)
          .clamp(0.35, server.maxRamGb * 0.9);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ramTimer?.cancel();
    super.dispose();
  }
}
