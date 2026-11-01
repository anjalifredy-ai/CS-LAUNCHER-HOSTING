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

  // Simulated console logs
  final Map<String, List<String>> _consoleLogs = {};
  List<String> getLogs(String serverId) => _consoleLogs[serverId] ?? [];

  // Simulated online players per server (name list)
  final Map<String, List<String>> _onlinePlayers = {};
  List<String> getOnlinePlayers(String serverId) =>
      List.unmodifiable(_onlinePlayers[serverId] ?? []);

  // Simulated operators
  final Map<String, Set<String>> _ops = {};

  // Simulated banned players
  final Map<String, Set<String>> _banned = {};

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
      publicAddress: 'tame-creeper-40.bore.pub',
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

    // Demo players
    _onlinePlayers[demo1.id] = ['Steve', 'Alex', 'Notch', 'Herobrine'];
    _ops[demo1.id] = {'Steve'};
    _banned[demo1.id] = {};

    _consoleLogs[demo1.id] = [
      '10:10:23 ERROR Could not lock the level file. Data corruption is possible if the world is accessed by multiple processes simultaneously. try_lock() not supported',
      '10:10:23 WARN Failed to get level_ using default instead: not found!',
      '10:10:23 INFO Starting parallel world load...',
      '10:10:23 INFO Loading minecraft:overworld',
      '10:10:23 INFO Loading minecraft:the_end',
      '10:10:23 INFO Loading minecraft:the_nether',
      '10:10:23 INFO All worlds loaded successfully.',
      '10:10:23 INFO Query protocol is enabled. Starting...',
      '10:10:24 INFO Done (3.241s)! For help, type "help"',
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
    _onlinePlayers.remove(id);
    _ops.remove(id);
    _banned.remove(id);
    if (_selectedServer?.id == id) {
      _selectedServer = null;
    }
    await _saveServers();
    notifyListeners();
  }

  // ==================== START / STOP ====================

  Future<void> startServer(String id) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final server = _servers[index];
    if (server.status == ServerStatus.online ||
        server.status == ServerStatus.starting) return;

    server.status = ServerStatus.starting;
    notifyListeners();

    _addLog(id, 'INFO Preparing server files...');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog(id, 'INFO Starting Java process...');
    await Future.delayed(const Duration(milliseconds: 700));
    _addLog(id, 'INFO Loading server.properties...');
    await Future.delayed(const Duration(milliseconds: 400));
    _addLog(id, 'INFO Starting parallel world load...');
    _addLog(id, 'INFO Loading minecraft:overworld');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog(id, 'INFO Loading minecraft:the_nether');
    _addLog(id, 'INFO Loading minecraft:the_end');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog(id, 'INFO All worlds loaded successfully.');
    _addLog(id, 'INFO Done (2.847s)! For help, type "help"');

    // bore.pub style public address
    final random = Random();
    final cleanName = server.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final tunnelName = 'cs-$cleanName-${random.nextInt(900) + 100}';
    server.publicAddress = '$tunnelName.bore.pub';

    server.status = ServerStatus.online;
    server.lastStarted = DateTime.now();
    server.usedRamGb = 0.45 + random.nextDouble() * 0.25;

    // Simulate some players joining after a short delay
    _onlinePlayers[id] = [];
    _ops.putIfAbsent(id, () => {});
    _banned.putIfAbsent(id, () => {});

    _startRamSimulation(id);

    // Fake join messages after a bit
    Future.delayed(const Duration(seconds: 2), () {
      if (server.status == ServerStatus.online) {
        _simulatePlayerJoin(id, 'Steve');
      }
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (server.status == ServerStatus.online) {
        _simulatePlayerJoin(id, 'Alex');
      }
    });

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

    _addLog(id, 'INFO Stopping the server...');
    await Future.delayed(const Duration(milliseconds: 400));

    // Kick all players
    final players = List<String>.from(_onlinePlayers[id] ?? []);
    for (final p in players) {
      _addLog(id, 'INFO $p left the game');
    }
    _onlinePlayers[id] = [];

    await Future.delayed(const Duration(milliseconds: 500));
    _addLog(id, 'INFO Saving players, worlds and other data...');
    await Future.delayed(const Duration(milliseconds: 700));
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
      if (index != -1) {
        _servers[index].onlinePlayers = players.length;
      }
      _addLog(id, 'INFO $name joined the game');
      notifyListeners();
    }
  }

  // ==================== CONSOLE COMMANDS ====================

  void _addLog(String id, String message) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

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
    } else if (message.startsWith('>')) {
      // User typed command - show as plain
      final log = '$time $message';
      _consoleLogs.putIfAbsent(id, () => []);
      _consoleLogs[id]!.add(log);
      if (_consoleLogs[id]!.length > 300) {
        _consoleLogs[id] =
            _consoleLogs[id]!.sublist(_consoleLogs[id]!.length - 300);
      }
      notifyListeners();
      return;
    }

    final log = '$time $level $cleanMsg';
    _consoleLogs.putIfAbsent(id, () => []);
    _consoleLogs[id]!.add(log);
    if (_consoleLogs[id]!.length > 300) {
      _consoleLogs[id] =
          _consoleLogs[id]!.sublist(_consoleLogs[id]!.length - 300);
    }
    notifyListeners();
  }

  void sendCommand(String serverId, String rawCommand) {
    final command = rawCommand.trim();
    if (command.isEmpty) return;

    final serverIndex = _servers.indexWhere((s) => s.id == serverId);
    if (serverIndex == -1) return;

    final server = _servers[serverIndex];

    // Always show what user typed
    _addLog(serverId, '> $command');

    // Server must be online for most commands
    if (server.status != ServerStatus.online) {
      _addLog(serverId, 'ERROR Server is not running. Start the server first.');
      return;
    }

    // Normalize: remove leading /
    String cmd = command.startsWith('/') ? command.substring(1) : command;
    final parts = cmd.split(RegExp(r'\s+'));
    final mainCmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    switch (mainCmd) {
      case 'help':
      case '?':
        _addLog(serverId, 'INFO --- CS LAUNCHER Commands ---');
        _addLog(serverId, 'INFO /list - List online players');
        _addLog(serverId, 'INFO /op <player> - Make player operator');
        _addLog(serverId, 'INFO /deop <player> - Remove operator');
        _addLog(serverId, 'INFO /kick <player> [reason] - Kick a player');
        _addLog(serverId, 'INFO /ban <player> [reason] - Ban a player');
        _addLog(serverId, 'INFO /pardon <player> - Unban a player');
        _addLog(serverId, 'INFO /say <message> - Broadcast message');
        _addLog(serverId, 'INFO /tp <player> <target> - Teleport');
        _addLog(serverId, 'INFO /gamemode <mode> [player] - Change gamemode');
        _addLog(serverId, 'INFO /difficulty <level> - Set difficulty');
        _addLog(serverId, 'INFO /whitelist <add|remove|list> [player]');
        _addLog(serverId, 'INFO /stop - Stop the server');
        _addLog(serverId, 'INFO /seed - Show world seed');
        _addLog(serverId, 'INFO /time set <day|night|value>');
        _addLog(serverId, 'INFO /weather <clear|rain|thunder>');
        break;

      case 'list':
        final players = _onlinePlayers[serverId] ?? [];
        if (players.isEmpty) {
          _addLog(serverId,
              'INFO There are 0 of a max of ${server.maxPlayers} players online');
        } else {
          _addLog(serverId,
              'INFO There are ${players.length} of a max of ${server.maxPlayers} players online: ${players.join(', ')}');
        }
        break;

      case 'op':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /op <player>');
        } else {
          final target = args[0];
          _ops.putIfAbsent(serverId, () => {}).add(target);
          _addLog(serverId, 'INFO Made $target a server operator');
        }
        break;

      case 'deop':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /deop <player>');
        } else {
          final target = args[0];
          _ops[serverId]?.remove(target);
          _addLog(serverId, 'INFO Made $target no longer a server operator');
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
        } else {
          final target = args[0];
          if (_banned[serverId]?.remove(target) == true) {
            _addLog(serverId, 'INFO Unbanned $target');
          } else {
            _addLog(serverId, 'ERROR That player is not banned');
          }
        }
        break;

      case 'say':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /say <message>');
        } else {
          final msg = args.join(' ');
          _addLog(serverId, 'INFO [Server] $msg');
        }
        break;

      case 'tp':
      case 'teleport':
        if (args.length < 2) {
          _addLog(serverId, 'ERROR Usage: /tp <player> <target>');
        } else {
          _addLog(serverId, 'INFO Teleported ${args[0]} to ${args[1]}');
        }
        break;

      case 'gamemode':
      case 'gm':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /gamemode <survival|creative|adventure|spectator> [player]');
        } else {
          final mode = args[0].toLowerCase();
          final target = args.length > 1 ? args[1] : 'Server';
          final valid = ['survival', 'creative', 'adventure', 'spectator', '0', '1', '2', '3', 's', 'c', 'a', 'sp'];
          if (valid.contains(mode)) {
            _addLog(serverId, 'INFO Set $target\'s game mode to $mode');
          } else {
            _addLog(serverId, 'ERROR Incorrect argument for command');
          }
        }
        break;

      case 'difficulty':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /difficulty <peaceful|easy|normal|hard>');
        } else {
          final diff = args[0].toLowerCase();
          if (['peaceful', 'easy', 'normal', 'hard', 'p', 'e', 'n', 'h'].contains(diff)) {
            server.difficulty = diff;
            _addLog(serverId, 'INFO Set game difficulty to $diff');
            _saveServers();
          } else {
            _addLog(serverId, 'ERROR Incorrect argument for command');
          }
        }
        break;

      case 'whitelist':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /whitelist <add|remove|list> [player]');
        } else {
          final sub = args[0].toLowerCase();
          if (sub == 'list') {
            _addLog(serverId, 'INFO There are 0 whitelisted players');
          } else if (sub == 'add' && args.length > 1) {
            _addLog(serverId, 'INFO Added ${args[1]} to the whitelist');
          } else if (sub == 'remove' && args.length > 1) {
            _addLog(serverId, 'INFO Removed ${args[1]} from the whitelist');
          } else {
            _addLog(serverId, 'ERROR Incorrect usage');
          }
        }
        break;

      case 'seed':
        _addLog(serverId, 'INFO Seed: [${Random().nextInt(999999999)}]');
        break;

      case 'time':
        if (args.length >= 2 && args[0].toLowerCase() == 'set') {
          final value = args[1].toLowerCase();
          if (value == 'day') {
            _addLog(serverId, 'INFO Set the time to 1000');
          } else if (value == 'night') {
            _addLog(serverId, 'INFO Set the time to 13000');
          } else if (value == 'noon') {
            _addLog(serverId, 'INFO Set the time to 6000');
          } else if (value == 'midnight') {
            _addLog(serverId, 'INFO Set the time to 18000');
          } else {
            _addLog(serverId, 'INFO Set the time to $value');
          }
        } else {
          _addLog(serverId, 'ERROR Usage: /time set <day|night|noon|midnight|value>');
        }
        break;

      case 'weather':
        if (args.isEmpty) {
          _addLog(serverId, 'ERROR Usage: /weather <clear|rain|thunder>');
        } else {
          final w = args[0].toLowerCase();
          if (['clear', 'rain', 'thunder'].contains(w)) {
            _addLog(serverId, 'INFO Set the weather to $w');
          } else {
            _addLog(serverId, 'ERROR Incorrect argument for command');
          }
        }
        break;

      case 'stop':
      case 'end':
        _addLog(serverId, 'INFO Stopping the server...');
        stopServer(serverId);
        break;

      case 'version':
      case 'ver':
        _addLog(serverId,
            'INFO This server is running ${server.softwareLabel} version ${server.version}');
        break;

      case 'plugins':
      case 'pl':
        _addLog(serverId, 'INFO Plugins (0): None installed yet');
        break;

      default:
        _addLog(serverId,
            'ERROR Unknown or incomplete command. Type "help" for help.');
    }

    notifyListeners();
  }

  // ==================== RAM SIMULATION ====================

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

      // Keep onlinePlayers in sync with list
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
