import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/server_model.dart';

class ServerProvider extends ChangeNotifier {
  List<ServerModel> _servers = [];
  List<ServerModel> get servers => _servers;

  ServerModel? _selectedServer;
  ServerModel? get selectedServer => _selectedServer;

  // Simulated console logs for demo
  final Map<String, List<String>> _consoleLogs = {};
  List<String> getLogs(String serverId) => _consoleLogs[serverId] ?? [];

  Timer? _ramTimer;

  ServerProvider() {
    _loadServers();
    // Demo servers for first run
    if (_servers.isEmpty) {
      _addDemoServers();
    }
  }

  void _addDemoServers() {
    final demo1 = ServerModel(
      id: 'demo-smp',
      name: 'SMP Server',
      description: 'Custom JAR · 20 players',
      software: ServerSoftware.paper,
      version: '1.21.1',
      status: ServerStatus.online,
      maxPlayers: 20,
      onlinePlayers: 4,
      usedRamGb: 0.6,
      maxRamGb: 2.0,
      publicAddress: 'tame-creeper-40.anvil-mc.app', // placeholder style
      motd: 'Powered with ❤️ by CS LAUNCHER',
    );

    final demo2 = ServerModel(
      id: 'demo-creative',
      name: 'Creative With Friends',
      description: 'Custom JAR · 20 players',
      software: ServerSoftware.paper,
      version: '1.21.1',
      status: ServerStatus.offline,
      maxPlayers: 20,
      maxRamGb: 1.5,
    );

    _servers = [demo1, demo2];
    _consoleLogs[demo1.id] = [
      '10:10:23 ERROR Could not lock the level file. Data corruption is possible if the world is accessed by multiple processes simultaneously. try_lock() not supported',
      '10:10:23 WARN Failed to get level_ using default instead: not found!',
      '10:10:23 INFO Starting parallel world load...',
      '10:10:23 INFO Loading minecraft:overworld',
      '10:10:23 INFO Loading minecraft:the_end',
      '10:10:23 INFO Loading minecraft:the_nether',
      '10:10:23 INFO All worlds loaded successfully.',
      '10:10:23 INFO Query protocol is enabled. Starting...',
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
      final data = jsonEncode(_servers.map((e) => e.toJson()).toList());
      await prefs.setString('servers', data);
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
    await _saveServers();
    notifyListeners();
  }

  Future<void> updateServer(ServerModel server) async {
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      _servers[index] = server;
      if (_selectedServer?.id == server.id) {
        _selectedServer = server;
      }
      await _saveServers();
      notifyListeners();
    }
  }

  Future<void> deleteServer(String id) async {
    _servers.removeWhere((s) => s.id == id);
    _consoleLogs.remove(id);
    if (_selectedServer?.id == id) {
      _selectedServer = null;
    }
    await _saveServers();
    notifyListeners();
  }

  // Simulated start (in real app this would launch Java process + bore tunnel)
  Future<void> startServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final server = _servers[index];
    server.status = ServerStatus.starting;
    notifyListeners();

    // Simulate startup logs
    _addLog(id, 'INFO Preparing server files...');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog(id, 'INFO Starting Java process...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog(id, 'INFO Loading server properties...');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog(id, 'INFO Starting parallel world load...');
    _addLog(id, 'INFO Loading minecraft:overworld');
    await Future.delayed(const Duration(milliseconds: 700));
    _addLog(id, 'INFO Loading minecraft:the_nether');
    _addLog(id, 'INFO Loading minecraft:the_end');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog(id, 'INFO All worlds loaded successfully.');
    _addLog(id, 'INFO Done (3.241s)! For help, type "help"');

    // Simulate bore.pub tunnel
    final random = Random();
    final tunnelName = 'cs-${server.name.toLowerCase().replaceAll(' ', '-')}-${random.nextInt(999)}';
    server.publicAddress = '$tunnelName.bore.pub';
    server.status = ServerStatus.online;
    server.lastStarted = DateTime.now();
    server.usedRamGb = 0.4 + random.nextDouble() * 0.3;

    // Start fake RAM fluctuation
    _startRamSimulation(id);

    await _saveServers();
    notifyListeners();
  }

  Future<void> stopServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final server = _servers[index];
    server.status = ServerStatus.stopping;
    notifyListeners();

    _addLog(id, 'INFO Stopping server...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog(id, 'INFO Saving worlds...');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog(id, 'INFO Server stopped.');

    server.status = ServerStatus.offline;
    server.onlinePlayers = 0;
    server.usedRamGb = 0.0;
    server.publicAddress = null;

    _ramTimer?.cancel();

    await _saveServers();
    notifyListeners();
  }

  void _addLog(String id, String message) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final level = message.startsWith('ERROR')
        ? 'ERROR'
        : message.startsWith('WARN')
            ? 'WARN'
            : 'INFO';
    final log = '$time $level $message';
    _consoleLogs.putIfAbsent(id, () => []);
    _consoleLogs[id]!.add(log);
    // Keep last 200 lines
    if (_consoleLogs[id]!.length > 200) {
      _consoleLogs[id] = _consoleLogs[id]!.sublist(_consoleLogs[id]!.length - 200);
    }
    notifyListeners();
  }

  void sendCommand(String serverId, String command) {
    if (command.trim().isEmpty) return;
    _addLog(serverId, '> $command');
    // Fake responses for common commands
    if (command.toLowerCase() == 'list') {
      final server = _servers.firstWhere((s) => s.id == serverId);
      _addLog(serverId, 'INFO There are ${server.onlinePlayers} of a max of ${server.maxPlayers} players online');
    } else if (command.toLowerCase().startsWith('op ')) {
      _addLog(serverId, 'INFO Made ${command.substring(3)} a server operator');
    } else if (command.toLowerCase() == 'stop') {
      stopServer(serverId);
    } else {
      _addLog(serverId, 'INFO Unknown or simulated command. Real execution coming soon.');
    }
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
      final random = Random();
      // Fluctuate around current usage
      double newUsage = server.usedRamGb + (random.nextDouble() - 0.5) * 0.15;
      newUsage = newUsage.clamp(0.3, server.maxRamGb * 0.95);
      server.usedRamGb = double.parse(newUsage.toStringAsFixed(2));
      // Random player count fluctuation
      if (random.nextBool()) {
        server.onlinePlayers = (server.onlinePlayers + random.nextInt(3) - 1).clamp(0, server.maxPlayers);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ramTimer?.cancel();
    super.dispose();
  }
}
