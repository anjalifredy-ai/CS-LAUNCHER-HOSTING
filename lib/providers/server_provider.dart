import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/server_model.dart';
import '../models/plugin_model.dart';

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
      publicAddress: 'tame-creeper-40.bore.pub:38472',
      motd: 'Powered with ❤️ by CS LAUNCHER',
      platformType: PlatformType.both,
      aiBuilderEnabled: true,
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
      platformType: PlatformType.java,
    );

    _servers = [demo1, demo2];

    _onlinePlayers[demo1.id] = ['Steve', 'Alex', 'Notch', 'Herobrine'];
    _ops[demo1.id] = {'Steve'};
    _banned[demo1.id] = {};
    _installedPlugins[demo1.id] = ['essentialsx', 'vault', 'luckperms'];

    _consoleLogs[demo1.id] = [
      '10:10:23 INFO Starting parallel world load...',
      '10:10:23 INFO Loading minecraft:overworld',
      '10:10:23 INFO Loading minecraft:the_end',
      '10:10:23 INFO Loading minecraft:the_nether',
      '10:10:23 INFO All worlds loaded successfully.',
      '10:10:24 INFO Done (3.241s)! For help, type "help"',
      '10:10:24 INFO Starting public tunnel (bore.pub)...',
      '10:10:25 INFO Tunnel established → tame-creeper-40.bore.pub:38472',
      '10:10:25 INFO Friends can join using the public address above',
      '10:10:25 INFO Platform: Java + Bedrock (Geyser + Floodgate)',
      '10:10:25 INFO AI Builder ready',
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

  bool isPluginInstalled(String serverId, String pluginId) {
    return (_installedPlugins[serverId] ?? []).contains(pluginId);
  }

  List<PluginModel> getInstalledPlugins(String serverId) {
    final ids = _installedPlugins[serverId] ?? [];
    return availablePlugins.where((p) => ids.contains(p.id)).toList();
  }

  Future<void> installPlugin(String serverId, String pluginId) async {
    final plugins = _installedPlugins.putIfAbsent(serverId, () => []);
    if (plugins.contains(pluginId)) return;
    final plugin = availablePlugins.firstWhere((p) => p.id == pluginId);
    _addLog(serverId, 'INFO Downloading ${plugin.name} v${plugin.version}...');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog(serverId, 'INFO Installing ${plugin.name}...');
    await Future.delayed(const Duration(milliseconds: 400));
    plugins.add(pluginId);
    _addLog(serverId, 'INFO Successfully installed ${plugin.name}');
    notifyListeners();
  }

  Future<void> uninstallPlugin(String serverId, String pluginId) async {
    final plugins = _installedPlugins[serverId];
    if (plugins == null || !plugins.contains(pluginId)) return;
    final plugin = availablePlugins.firstWhere((p) => p.id == pluginId);
    _addLog(serverId, 'INFO Uninstalling ${plugin.name}...');
    await Future.delayed(const Duration(milliseconds: 300));
    plugins.remove(pluginId);
    _addLog(serverId, 'INFO Successfully uninstalled ${plugin.name}');
    notifyListeners();
  }

  Future<void> startServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final server = _servers[index];
    if (server.status == ServerStatus.online || server.status == ServerStatus.starting) return;

    server.status = ServerStatus.starting;
    notifyListeners();

    _addLog(id, 'INFO Preparing server files...');
    if (server.hasCustomWorld && server.worldPath != null) {
      _addLog(id, 'INFO Loading imported world: ${server.worldPath}');
    }
    await Future.delayed(const Duration(milliseconds: 350));

    if (server.platformType == PlatformType.bedrock) {
      _addLog(id, 'INFO Starting PowerNukkitX (Bedrock) process...');
    } else {
      _addLog(id, 'INFO Starting Java process...');
    }
    await Future.delayed(const Duration(milliseconds: 550));

    final installed = _installedPlugins[id] ?? [];
    if (installed.isNotEmpty) {
      _addLog(id, 'INFO Loading ${installed.length} plugin(s)...');
      for (final pid in installed) {
        final p = availablePlugins.firstWhere((e) => e.id == pid);
        await Future.delayed(const Duration(milliseconds: 120));
        _addLog(id, 'INFO [Plugins] Loaded ${p.name} v${p.version}');
      }
    }

    if (server.platformType == PlatformType.both) {
      _addLog(id, 'INFO Loading Geyser + Floodgate for Bedrock cross-play...');
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _addLog(id, 'INFO Loading server.properties...');
    await Future.delayed(const Duration(milliseconds: 250));
    _addLog(id, 'INFO Starting parallel world load...');
    _addLog(id, 'INFO Loading minecraft:overworld');
    await Future.delayed(const Duration(milliseconds: 450));
    _addLog(id, 'INFO Loading minecraft:the_nether');
    _addLog(id, 'INFO Loading minecraft:the_end');
    await Future.delayed(const Duration(milliseconds: 350));
    _addLog(id, 'INFO All worlds loaded successfully.');
    _addLog(id, 'INFO Done (2.847s)! For help, type "help"');

    _addLog(id, 'INFO Starting public tunnel (bore.pub)...');
    await Future.delayed(const Duration(milliseconds: 450));
    final random = Random();
    final port = 30000 + random.nextInt(20000);
    final cleanName = server.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final host = 'cs-$cleanName-${random.nextInt(900) + 100}.bore.pub';
    server.publicAddress = '$host:$port';
    _addLog(id, 'INFO Tunnel established → ${server.publicAddress}');
    _addLog(id, 'INFO Friends can join using the public address above');
    _addLog(id, 'INFO Platform: ${server.platformLabel}');

    if (server.aiBuilderEnabled) {
      _addLog(id, 'INFO AI Builder ready — describe builds in the AI tab');
    }

    server.status = ServerStatus.online;
    server.lastStarted = DateTime.now();
    server.usedRamGb = 0.45 + random.nextDouble() * 0.25;

    _onlinePlayers[id] = [];
    _ops.putIfAbsent(id, () => {});
    _banned.putIfAbsent(id, () => {});

    _startRamSimulation(id);

    Future.delayed(const Duration(seconds: 2), () {
      if (server.status == ServerStatus.online) _simulatePlayerJoin(id, 'Steve');
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (server.status == ServerStatus.online) _simulatePlayerJoin(id, 'Alex');
    });

    await _saveServers();
    notifyListeners();
  }

  Future<void> stopServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final server = _servers[index];
    if (server.status == ServerStatus.offline || server.status == ServerStatus.stopping) return;

    server.status = ServerStatus.stopping;
    notifyListeners();

    _addLog(id, 'INFO Stopping the server...');
    await Future.delayed(const Duration(milliseconds: 350));
    _addLog(id, 'INFO Closing public tunnel...');

    final players = List<String>.from(_onlinePlayers[id] ?? []);
    for (final p in players) {
      _addLog(id, 'INFO $p left the game');
    }
    _onlinePlayers[id] = [];

    await Future.delayed(const Duration(milliseconds: 400));
    _addLog(id, 'INFO Saving players, worlds and other data...');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog(id, 'INFO Server stopped.');

    server.status = ServerStatus.offline;
    server.onlinePlayers = 0;
    server.usedRamGb = 0.0;
    server.publicAddress = null;

    _ramTimer?.cancel();
    await _saveServers();
    notifyListeners();
  }

  void _simulatePlayerJoin(String id, String name) {
    final players = _onlinePlayers.putIfAbsent(id, () => []);
    if (!players.contains(name)) {
      players.add(name);
      final index = _servers.indexWhere((s) => s.id == id);
      if (index != -1) _servers[index].onlinePlayers = players.length;
      _addLog(id, 'INFO $name joined the game');
      notifyListeners();
    }
  }

  void _addLog(String id, String message) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    if (message.startsWith('>')) {
      final log = '$time $message';
      _consoleLogs.putIfAbsent(id, () => []);
      _consoleLogs[id]!.add(log);
      if (_consoleLogs[id]!.length > 300) {
        _consoleLogs[id] = _consoleLogs[id]!.sublist(_consoleLogs[id]!.length - 300);
      }
      notifyListeners();
      return;
    }

    String level = 'INFO';
    String cleanMsg = message;
    if (message.startsWith('ERROR')) {
      level = 'ERROR';
      cleanMsg = message.substring(5).trim();
    } else if (message.startsWith('WARN')) {
      level = 'WARN';
      cleanMsg = message.substring(4).trim();
    } else if (message.startsWith('INFO')) {
      level = 'INFO';
      cleanMsg = message.substring(4).trim();
    }

    final log = '$time $level $cleanMsg';
    _consoleLogs.putIfAbsent(id, () => []);
    _consoleLogs[id]!.add(log);
    if (_consoleLogs[id]!.length > 300) {
      _consoleLogs[id] = _consoleLogs[id]!.sublist(_consoleLogs[id]!.length - 300);
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
      _addLog(serverId, 'ERROR Server is not running. Start the server first.');
      return;
    }

    String cmd = command.startsWith('/') ? command.substring(1) : command;
    final parts = cmd.split(RegExp(r'\s+'));
    final mainCmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    switch (mainCmd) {
      case 'help':
      case '?':
        _addLog(serverId, 'INFO --- CS LAUNCHER Commands ---');
        _addLog(serverId, 'INFO /list /op /deop /kick /ban /pardon /say /plugins /stop');
        _addLog(serverId, 'INFO /tp /gamemode /difficulty /time /weather /whitelist');
        break;
      case 'list':
        final players = _onlinePlayers[serverId] ?? [];
        if (players.isEmpty) {
          _addLog(serverId, 'INFO There are 0 of a max of ${server.maxPlayers} players online');
        } else {
          _addLog(serverId, 'INFO There are ${players.length} of a max of ${server.maxPlayers} players online: ${players.join(', ')}');
        }
        break;
      case 'op':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /op <player>');
        } else {
          _ops.putIfAbsent(serverId, () => {}).add(args[0]);
          _addLog(serverId, 'INFO Made ${args[0]} a server operator');
        }
        break;
      case 'deop':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /deop <player>');
        } else {
          _ops[serverId]?.remove(args[0]);
          _addLog(serverId, 'INFO Made ${args[0]} no longer a server operator');
        }
        break;
      case 'kick':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /kick <player> [reason]');
        } else {
          final target = args[0];
          final reason = args.length > 1 ? args.sublist(1).join(' ') : 'Kicked by an operator';
          final players = _onlinePlayers[serverId] ?? [];
          if (players.contains(target)) {
            players.remove(target);
            server.onlinePlayers = players.length;
            _addLog(serverId, 'INFO Kicked $target: $reason');
            _addLog(serverId, 'INFO $target left the game');
          } else {
            _addLog(serverId, 'ERROR That player cannot be found');
          }
        }
        break;
      case 'ban':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /ban <player> [reason]');
        } else {
          final target = args[0];
          final reason = args.length > 1 ? args.sublist(1).join(' ') : 'Banned by an operator';
          _banned.putIfAbsent(serverId, () => {}).add(target);
          final players = _onlinePlayers[serverId] ?? [];
          if (players.contains(target)) {
            players.remove(target);
            server.onlinePlayers = players.length;
            _addLog(serverId, 'INFO $target left the game');
          }
          _addLog(serverId, 'INFO Banned $target: $reason');
        }
        break;
      case 'pardon':
      case 'unban':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /pardon <player>');
        } else if (_banned[serverId]?.remove(args[0]) == true) {
          _addLog(serverId, 'INFO Unbanned ${args[0]}');
        } else {
          _addLog(serverId, 'ERROR That player is not banned');
        }
        break;
      case 'say':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /say <message>');
        } else {
          _addLog(serverId, 'INFO [Server] ${args.join(' ')}');
        }
        break;
      case 'plugins':
      case 'pl':
        final installed = getInstalledPlugins(serverId);
        if (installed.isEmpty) {
          _addLog(serverId, 'INFO Plugins (0): None installed');
        } else {
          _addLog(serverId, 'INFO Plugins (${installed.length}): ${installed.map((p) => p.name).join(', ')}');
        }
        break;
      case 'stop':
      case 'end':
        _addLog(serverId, 'INFO Stopping the server...');
        stopServer(serverId);
        break;
      case 'version':
      case 'ver':
        _addLog(serverId, 'INFO This server is running ${server.softwareLabel} version ${server.version}');
        break;
      default:
        _addLog(serverId, 'ERROR Unknown or incomplete command. Type "help" for help.');
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
      final random = Random();
      double newUsage = server.usedRamGb + (random.nextDouble() - 0.5) * 0.12;
      newUsage = newUsage.clamp(0.35, server.maxRamGb * 0.92);
      server.usedRamGb = double.parse(newUsage.toStringAsFixed(2));
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
