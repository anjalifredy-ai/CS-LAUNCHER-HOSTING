class PluginModel {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final int downloads;
  final String category; // utility, gameplay, economy, etc.
  final List<String> supportedVersions;
  bool isInstalled;

  PluginModel({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.downloads,
    required this.category,
    required this.supportedVersions,
    this.isInstalled = false,
  });

  PluginModel copyWith({bool? isInstalled}) {
    return PluginModel(
      id: id,
      name: name,
      description: description,
      author: author,
      version: version,
      downloads: downloads,
      category: category,
      supportedVersions: supportedVersions,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }
}

// Popular plugins for simulation (inspired by real ones)
List<PluginModel> getPopularPlugins() {
  return [
    PluginModel(
      id: 'essentialsx',
      name: 'EssentialsX',
      description: 'The essential plugin suite for Minecraft servers. Homes, warps, kits, economy and more.',
      author: 'EssentialsX Team',
      version: '2.21.0',
      downloads: 18500000,
      category: 'Utility',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4', '1.20.1'],
    ),
    PluginModel(
      id: 'luckperms',
      name: 'LuckPerms',
      description: 'An advanced permissions plugin for Bukkit/Spigot/Paper and more.',
      author: 'Luck',
      version: '5.4.141',
      downloads: 9200000,
      category: 'Admin',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4'],
    ),
    PluginModel(
      id: 'worldedit',
      name: 'WorldEdit',
      description: 'In-game map editor for making big changes to your world fast.',
      author: 'EngineHub',
      version: '7.3.4',
      downloads: 15400000,
      category: 'World',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4', '1.20.1'],
    ),
    PluginModel(
      id: 'worldguard',
      name: 'WorldGuard',
      description: 'Protect areas, manage flags, block explosions and more.',
      author: 'EngineHub',
      version: '7.0.11',
      downloads: 11200000,
      category: 'Protection',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4'],
    ),
    PluginModel(
      id: 'vault',
      name: 'Vault',
      description: 'Permissions, Chat, & Economy API for server plugins.',
      author: 'MilkBowl',
      version: '1.7.3',
      downloads: 8700000,
      category: 'API',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4', '1.20.1', '1.19.4'],
    ),
    PluginModel(
      id: 'coreprotect',
      name: 'CoreProtect',
      description: 'Fast and efficient block logging and rollback plugin.',
      author: 'Intelli',
      version: '22.4',
      downloads: 6800000,
      category: 'Admin',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4'],
    ),
    PluginModel(
      id: 'placeholderapi',
      name: 'PlaceholderAPI',
      description: 'The best and simplest way to add placeholders to your server.',
      author: 'HelpChat',
      version: '2.11.6',
      downloads: 9500000,
      category: 'API',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4', '1.20.1'],
    ),
    PluginModel(
      id: 'citizens',
      name: 'Citizens',
      description: 'Create NPCs for your server with ease.',
      author: 'CitizensNPCs',
      version: '2.0.35',
      downloads: 4200000,
      category: 'Gameplay',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4'],
    ),
    PluginModel(
      id: 'multiverse-core',
      name: 'Multiverse-Core',
      description: 'Create and manage multiple worlds easily.',
      author: 'Multiverse',
      version: '4.3.12',
      downloads: 5100000,
      category: 'World',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4', '1.20.1'],
    ),
    PluginModel(
      id: 'spark',
      name: 'spark',
      description: 'Performance profiler and monitoring tool for Minecraft servers.',
      author: 'Luck',
      version: '1.10.86',
      downloads: 3800000,
      category: 'Utility',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4'],
    ),
    PluginModel(
      id: 'viaversion',
      name: 'ViaVersion',
      description: 'Allows newer clients to join older server versions.',
      author: 'ViaVersion',
      version: '5.0.3',
      downloads: 7200000,
      category: 'Utility',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4', '1.20.1', '1.19.4'],
    ),
    PluginModel(
      id: 'protocolib',
      name: 'ProtocolLib',
      description: 'Provides read/write access to the Minecraft protocol.',
      author: 'dmulloy2',
      version: '5.3.0',
      downloads: 6100000,
      category: 'API',
      supportedVersions: ['1.21.1', '1.21', '1.20.6', '1.20.4'],
    ),
  ];
}
