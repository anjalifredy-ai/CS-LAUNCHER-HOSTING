import 'package:flutter/material.dart';

enum ServerSoftware {
  paper,
  purpur,
  spigot,
  fabric,
  neoforge,
  forge,
  vanilla,
  optifine, // client side mostly, but for completeness
}

enum ServerStatus {
  offline,
  starting,
  online,
  stopping,
  error,
}

class ServerModel {
  final String id;
  String name;
  String description;
  String? iconPath; // local path or asset
  ServerSoftware software;
  String version; // e.g. "1.21.1"
  ServerStatus status;
  int maxPlayers;
  int onlinePlayers;
  double usedRamGb;
  double maxRamGb;
  bool onlineMode;
  bool allowSkins;
  bool pvp;
  bool hardcore;
  String difficulty; // peaceful, easy, normal, hard
  String gamemode; // survival, creative, adventure, spectator
  int viewDistance;
  int simulationDistance;
  String? publicAddress; // bore.pub address
  int port;
  DateTime createdAt;
  DateTime? lastStarted;
  String motd;

  ServerModel({
    required this.id,
    required this.name,
    this.description = '',
    this.iconPath,
    this.software = ServerSoftware.paper,
    this.version = '1.21.1',
    this.status = ServerStatus.offline,
    this.maxPlayers = 20,
    this.onlinePlayers = 0,
    this.usedRamGb = 0.0,
    this.maxRamGb = 2.0,
    this.onlineMode = true,
    this.allowSkins = true,
    this.pvp = true,
    this.hardcore = false,
    this.difficulty = 'normal',
    this.gamemode = 'survival',
    this.viewDistance = 10,
    this.simulationDistance = 10,
    this.publicAddress,
    this.port = 25565,
    DateTime? createdAt,
    this.lastStarted,
    this.motd = 'A Minecraft Server powered by CS LAUNCHER',
  }) : createdAt = createdAt ?? DateTime.now();

  String get softwareLabel {
    switch (software) {
      case ServerSoftware.paper:
        return 'Paper';
      case ServerSoftware.purpur:
        return 'Purpur';
      case ServerSoftware.spigot:
        return 'Spigot';
      case ServerSoftware.fabric:
        return 'Fabric';
      case ServerSoftware.neoforge:
        return 'NeoForge';
      case ServerSoftware.forge:
        return 'Forge';
      case ServerSoftware.vanilla:
        return 'Vanilla';
      case ServerSoftware.optifine:
        return 'OptiFine';
    }
  }

  String get statusLabel {
    switch (status) {
      case ServerStatus.offline:
        return 'OFFLINE';
      case ServerStatus.starting:
        return 'STARTING';
      case ServerStatus.online:
        return 'ONLINE';
      case ServerStatus.stopping:
        return 'STOPPING';
      case ServerStatus.error:
        return 'ERROR';
    }
  }

  Color get statusColor {
    switch (status) {
      case ServerStatus.offline:
        return const Color(0xFF757575);
      case ServerStatus.starting:
      case ServerStatus.stopping:
        return const Color(0xFFFFAB40);
      case ServerStatus.online:
        return const Color(0xFF00C853);
      case ServerStatus.error:
        return const Color(0xFFFF5252);
    }
  }

  // For UI display like in screenshots
  String get subtitle {
    return '${softwareLabel} JAR · $maxPlayers players';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'software': software.name,
      'version': version,
      'status': status.name,
      'maxPlayers': maxPlayers,
      'onlinePlayers': onlinePlayers,
      'usedRamGb': usedRamGb,
      'maxRamGb': maxRamGb,
      'onlineMode': onlineMode,
      'allowSkins': allowSkins,
      'pvp': pvp,
      'hardcore': hardcore,
      'difficulty': difficulty,
      'gamemode': gamemode,
      'viewDistance': viewDistance,
      'simulationDistance': simulationDistance,
      'publicAddress': publicAddress,
      'port': port,
      'createdAt': createdAt.toIso8601String(),
      'lastStarted': lastStarted?.toIso8601String(),
      'motd': motd,
    };
  }

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      iconPath: json['iconPath'],
      software: ServerSoftware.values.firstWhere(
        (e) => e.name == json['software'],
        orElse: () => ServerSoftware.paper,
      ),
      version: json['version'] ?? '1.21.1',
      status: ServerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ServerStatus.offline,
      ),
      maxPlayers: json['maxPlayers'] ?? 20,
      onlinePlayers: json['onlinePlayers'] ?? 0,
      usedRamGb: (json['usedRamGb'] ?? 0.0).toDouble(),
      maxRamGb: (json['maxRamGb'] ?? 2.0).toDouble(),
      onlineMode: json['onlineMode'] ?? true,
      allowSkins: json['allowSkins'] ?? true,
      pvp: json['pvp'] ?? true,
      hardcore: json['hardcore'] ?? false,
      difficulty: json['difficulty'] ?? 'normal',
      gamemode: json['gamemode'] ?? 'survival',
      viewDistance: json['viewDistance'] ?? 10,
      simulationDistance: json['simulationDistance'] ?? 10,
      publicAddress: json['publicAddress'],
      port: json['port'] ?? 25565,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastStarted: json['lastStarted'] != null
          ? DateTime.tryParse(json['lastStarted'])
          : null,
      motd: json['motd'] ?? 'A Minecraft Server powered by CS LAUNCHER',
    );
  }
}
