import 'package:flutter/material.dart';

enum ServerSoftware {
  paper,
  purpur,
  spigot,
  fabric,
  neoforge,
  forge,
  vanilla,
  powernukkitx,
  pumpkin,
}

enum ServerStatus {
  offline,
  starting,
  online,
  stopping,
  error,
}

enum GameTemplate {
  none,
  survival,
  creative,
  skyblock,
  oneblock,
  acidisland,
  caveblock,
}

enum PlatformType {
  java,
  bedrock,
  both,
}

/// Who provides the public tunnel
enum TunnelProvider {
  csTunnel, // Our own free network (self-hosted bore)
  borePub, // Public bore.pub
  custom, // User-defined host
}

class ServerModel {
  final String id;
  String name;
  String description;
  String? iconPath;
  ServerSoftware software;
  String version;
  ServerStatus status;
  int maxPlayers;
  int onlinePlayers;
  double usedRamGb;
  double maxRamGb;
  bool onlineMode;
  bool allowSkins;
  bool pvp;
  bool hardcore;
  String difficulty;
  String gamemode;
  int viewDistance;
  int simulationDistance;
  String? publicAddress;
  int port;
  DateTime createdAt;
  DateTime? lastStarted;
  String motd;

  PlatformType platformType;
  bool whitelistEnabled;
  GameTemplate template;
  String tunnelRegion;

  // Tunnel
  TunnelProvider tunnelProvider;
  String tunnelHost; // e.g. tunnel.cs-launcher.xyz or bore.pub

  String? worldPath;
  bool hasCustomWorld;
  bool aiBuilderEnabled;

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
    this.platformType = PlatformType.java,
    this.whitelistEnabled = false,
    this.template = GameTemplate.none,
    this.tunnelRegion = 'EU',
    this.tunnelProvider = TunnelProvider.csTunnel,
    this.tunnelHost = 'tunnel.cs-launcher.xyz',
    this.worldPath,
    this.hasCustomWorld = false,
    this.aiBuilderEnabled = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get bedrockSupport =>
      platformType == PlatformType.bedrock || platformType == PlatformType.both;

  bool get javaSupport =>
      platformType == PlatformType.java || platformType == PlatformType.both;

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
      case ServerSoftware.powernukkitx:
        return 'PowerNukkitX';
      case ServerSoftware.pumpkin:
        return 'Pumpkin';
    }
  }

  String get platformLabel {
    switch (platformType) {
      case PlatformType.java:
        return 'Java';
      case PlatformType.bedrock:
        return 'Bedrock';
      case PlatformType.both:
        return 'Java + Bedrock';
    }
  }

  String get tunnelProviderLabel {
    switch (tunnelProvider) {
      case TunnelProvider.csTunnel:
        return 'CS Tunnel (Free)';
      case TunnelProvider.borePub:
        return 'bore.pub';
      case TunnelProvider.custom:
        return 'Custom';
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

  String get subtitle {
    final base = '$softwareLabel · $maxPlayers players';
    switch (platformType) {
      case PlatformType.both:
        return '$base · Cross-play';
      case PlatformType.bedrock:
        return '$base · Bedrock';
      case PlatformType.java:
        return base;
    }
  }

  String get templateLabel {
    switch (template) {
      case GameTemplate.none:
        return 'Custom';
      case GameTemplate.survival:
        return 'Survival';
      case GameTemplate.creative:
        return 'Creative';
      case GameTemplate.skyblock:
        return 'SkyBlock';
      case GameTemplate.oneblock:
        return 'OneBlock';
      case GameTemplate.acidisland:
        return 'AcidIsland';
      case GameTemplate.caveblock:
        return 'CaveBlock';
    }
  }

  /// Host used when opening a tunnel
  String get effectiveTunnelHost {
    switch (tunnelProvider) {
      case TunnelProvider.csTunnel:
        return tunnelHost.isNotEmpty ? tunnelHost : 'tunnel.cs-launcher.xyz';
      case TunnelProvider.borePub:
        return 'bore.pub';
      case TunnelProvider.custom:
        return tunnelHost.isNotEmpty ? tunnelHost : 'bore.pub';
    }
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
      'platformType': platformType.name,
      'whitelistEnabled': whitelistEnabled,
      'template': template.name,
      'tunnelRegion': tunnelRegion,
      'tunnelProvider': tunnelProvider.name,
      'tunnelHost': tunnelHost,
      'worldPath': worldPath,
      'hasCustomWorld': hasCustomWorld,
      'aiBuilderEnabled': aiBuilderEnabled,
    };
  }

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    PlatformType platform = PlatformType.java;
    if (json['platformType'] != null) {
      platform = PlatformType.values.firstWhere(
        (e) => e.name == json['platformType'],
        orElse: () => PlatformType.java,
      );
    } else if (json['bedrockSupport'] == true) {
      platform = PlatformType.both;
    }

    TunnelProvider tp = TunnelProvider.csTunnel;
    if (json['tunnelProvider'] != null) {
      tp = TunnelProvider.values.firstWhere(
        (e) => e.name == json['tunnelProvider'],
        orElse: () => TunnelProvider.csTunnel,
      );
    }

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
      platformType: platform,
      whitelistEnabled: json['whitelistEnabled'] ?? false,
      template: GameTemplate.values.firstWhere(
        (e) => e.name == json['template'],
        orElse: () => GameTemplate.none,
      ),
      tunnelRegion: json['tunnelRegion'] ?? 'EU',
      tunnelProvider: tp,
      tunnelHost: json['tunnelHost'] ?? 'tunnel.cs-launcher.xyz',
      worldPath: json['worldPath'],
      hasCustomWorld: json['hasCustomWorld'] ?? false,
      aiBuilderEnabled: json['aiBuilderEnabled'] ?? false,
    );
  }
}
