import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/server_model.dart';
import '../models/plugin_model.dart';
import '../services/native_host_service.dart';

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
      status: ServerStatus.online,
      maxPlayers: 20,
      onlinePlayers: 4,
      usedRamGb: 0.6,
      maxRamGb: 2.0,
      publicAddress: 'bore.pub:33421',
      motd: 'Powered with love by CS LAUNCHER',
      platformType: PlatformType.both,
      aiBuilderEnabled: true,
      tunnelProvider: TunnelProvider.borePub,
      tunnelHost: 'bore.pub',
    );
    final demo2 = ServerModel(
      id: 'demo-creative',
      name: 'Creative With Friends',
      software: ServerSoftware.paper,
      version: '1.21.1',
      status: ServerStatus.offline,
      maxPlayers: 20,
      maxRamGb: 1.5,
      tunnelProvider: TunnelProvider.borePub,
    );
    _servers = [demo1, demo2];
    _onlinePlayers[demo1.id] = ['Steve', 'Alex', 'Notch', 'Herobrine'];
    _ops[demo1.id] = {'Steve'};
    _installedPlugins[demo1.id] = ['essentialsx', 'vault', 'luckperms'];
    _consoleLogs[demo1.id] = [
      'INFO Done (3.241s)! For help, type "help"',
      'INFO Starting bore.pub tunnel...',
      'INFO Tunnel established → bore.pub:33421',
    ];
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
      debugPrint('Error saving servers: $e');
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
    _ops.remove(id);
    _banned.remove(id);
    _installedPlugins.remove(id);
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
    final plugin = availablePlugins.firstWhere((p) => p.id == pluginId);
    _addLog(serverId, 'INFO Downloading ${plugin.name}...');
    await Future.delayed(const Duration(milliseconds: 500));
    plugins.add(pluginId);
    _addLog(serverId, 'INFO Installed ${plugin.name}');
    notifyListeners();
  }

  Future<void> uninstallPlugin(String serverId, String pluginId) async {
    final plugins = _installedPlugins[serverId];
    if (plugins == null || !plugins.contains(pluginId)) return;
    plugins.remove(pluginId);
    _addLog(serverId, 'INFO Uninstalled plugin');
    notifyListeners();
  }

  Future<void> startServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final server = _servers[index];
    if (server.status == ServerStatus.online ||
        server.status == ServerStatus.starting) return;

    server.status = ServerStatus.starting;
    notifyListeners();

    _addLog(id, 'INFO Preparing server files...');
    await Future.delayed(const Duration(milliseconds: 300));
    _addLog(id, 'INFO Starting game process...');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog(id, 'INFO Done (2.1s)! For help, type "help"');

    // --- Real bore.pub if binary present, else simulate ---
    final toHost = server.tunnelProvider == TunnelProvider.borePub
        ? 'bore.pub'
        : server.effectiveTunnelHost;

    _addLog(id, 'INFO Connecting tunnel → $toHost ...');
    final tunnel = await NativeHostService.startTunnel(
      serverId: id,
      localPort: server.port,
      toHost: toHost,
    );

    if (tunnel['ok'] == true && tunnel['publicAddress'] != null) {
      server.publicAddress = tunnel['publicAddress'] as String;
      _addLog(id, 'INFO REAL tunnel: ${server.publicAddress}');
    } else {
      final reason = tunnel['message'] ?? tunnel['mode'] ?? 'simulate';
      _addLog(id, 'WARN Tunnel native: $reason');
      _addLog(id, 'INFO Using simulated address (put bore binary for real)');
      final random = Random();
      final port = 30000 + random.nextInt(10000);
      server.publicAddress = '$toHost:$port';
      _addLog(id, 'INFO Tunnel (demo) → ${server.publicAddress}');
    }

    _addLog(id, 'INFO Friends can join: ${server.publicAddress}');
    server.status = ServerStatus.online;
    server.lastStarted = DateTime.now();
    server.usedRamGb = 0.5;
    _onlinePlayers[id] = [];
    _startRamSimulation(id);
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
    await Future.delayed(const Duration(milliseconds: 400));
    _onlinePlayers[id] = [];
    server.status = ServerStatus.offline;
    server.onlinePlayers = 0;
    server.usedRamGb = 0;
    server.publicAddress = null;
    _ramTimer?.cancel();
    _addLog(id, 'INFO Server stopped.');
    await _saveServers();
    notifyListeners();
  }

  void _simulatePlayerJoin(String id, String name) {
    final players = _onlinePlayers.putIfAbsent(id, () => []);
    if (!players.contains(name)) {
      players.add(name);
      final i = _servers.indexWhere((s) => s.id == id);
      if (i != -1) _servers[i].onlinePlayers = players.length;
      _addLog(id, 'INFO $name joined the game');
      notifyListeners();
    }
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
    String cmd = command.startsWith('/') ? command.substring(1) : command;
    final parts = cmd.split(RegExp(r'\s+'));
    final mainCmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];
    switch (mainCmd) {
      case 'help':
        _addLog(serverId, 'INFO /list /op /kick /ban /stop /plugins');
        break;
      case 'list':
        final p = _onlinePlayers[serverId] ?? [];
        _addLog(serverId, 'INFO ${p.length}/${server.maxPlayers}: ${p.join(', ')}');
        break;
      case 'op':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /op <player>');
        } else {
          _ops.putIfAbsent(serverId, () => {}).add(args[0]);
          _addLog(serverId, 'INFO Opped ${args[0]}');
        }
        break;
      case 'kick':
        if (args.isNotEmpty) {
          (_onlinePlayers[serverId] ?? []).remove(args[0]);
          server.onlinePlayers = (_onlinePlayers[serverId] ?? []).length;
          _addLog(serverId, 'INFO Kicked ${args[0]}');
        }
        break;
      case 'stop':
        stopServer(serverId);
        break;
      case 'plugins':
        final inst = getInstalledPlugins(serverId);
        _addLog(serverId, 'INFO Plugins: ${inst.map((e) => e.name).join(', ')}');
        break;
      default:
        _addLog(serverId, 'ERROR Unknown command');
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
      server.onlinePlayers = (_onlinePlayers[id] ?? []).length;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ramTimer?.cancel();
    super.dispose();
  }
}
