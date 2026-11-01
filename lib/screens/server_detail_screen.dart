import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../providers/server_provider.dart';
import '../models/server_model.dart';
import 'server_settings_screen.dart';
import 'plugins_screen.dart';
import 'ai_builder_screen.dart';
import 'file_browser_screen.dart';

class ServerDetailScreen extends StatefulWidget {
  final String serverId;
  const ServerDetailScreen({super.key, required this.serverId});

  @override
  State<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends State<ServerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commandController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        final server = provider.servers.firstWhere(
          (s) => s.id == widget.serverId,
          orElse: () => ServerModel(id: '', name: 'Unknown'),
        );

        if (server.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Server not found')),
            body: const Center(child: Text('This server no longer exists.')),
          );
        }

        final logs = provider.getLogs(server.id);
        final isOnline = server.status == ServerStatus.online;
        final installedCount = provider.getInstalledPluginIds(server.id).length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(server.name),
            actions: [
              // AI Builder
              IconButton(
                icon: const Icon(Icons.smart_toy_outlined),
                tooltip: 'AI Builder',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiBuilderScreen(serverId: server.id),
                    ),
                  );
                },
              ),
              // Files
              IconButton(
                icon: const Icon(Icons.folder_outlined),
                tooltip: 'Files',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FileBrowserScreen(
                        serverId: server.id,
                        serverName: server.name,
                      ),
                    ),
                  );
                },
              ),
              // Plugins
              IconButton(
                icon: Badge(
                  isLabelVisible: installedCount > 0,
                  label: Text('$installedCount'),
                  child: const Icon(Icons.extension),
                ),
                tooltip: 'Plugins',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PluginsScreen(serverId: server.id),
                    ),
                  );
                },
              ),
              // Start / Stop
              if (isOnline)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.error),
                  tooltip: 'Stop',
                  onPressed: () => provider.stopServer(server.id),
                )
              else
                IconButton(
                  icon: const Icon(Icons.play_circle_outline, color: AppTheme.primaryGreen),
                  tooltip: 'Start',
                  onPressed: () => provider.startServer(server.id),
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServerSettingsScreen(serverId: server.id),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(text: 'CONSOLE'),
                Tab(text: 'PLAYERS'),
                Tab(text: 'INFO'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // CONSOLE
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppTheme.surface,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline ? AppTheme.primaryGreen : AppTheme.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-- LIVE OUTPUT --',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          server.statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: server.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: logs.isEmpty
                        ? Center(
                            child: Text(
                              'No logs yet.\nStart the server to see output.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppTheme.textMuted),
                            ),
                          )
                        : ListView.builder(
                            controller: _logScrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              return _LogLine(log: logs[index]);
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(top: BorderSide(color: AppTheme.surfaceLight)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commandController,
                              enabled: isOnline,
                              style: GoogleFonts.robotoMono(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: isOnline
                                    ? 'Enter command... (e.g. /op Steve)'
                                    : 'Start the server first...',
                                hintStyle: GoogleFonts.robotoMono(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                prefixIcon: const Icon(
                                  Icons.terminal,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty && isOnline) {
                                  provider.sendCommand(server.id, value.trim());
                                  _commandController.clear();
                                  _scrollToBottom();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isOnline ? AppTheme.primaryGreen : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: isOnline
                                  ? () {
                                      final value = _commandController.text.trim();
                                      if (value.isNotEmpty) {
                                        provider.sendCommand(server.id, value);
                                        _commandController.clear();
                                        _scrollToBottom();
                                      }
                                    }
                                  : null,
                              icon: Icon(
                                Icons.send_rounded,
                                color: isOnline ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              _PlayersTab(serverId: server.id, server: server),
              _InfoTab(server: server, provider: provider),
            ],
          ),
        );
      },
    );
  }
}

class _LogLine extends StatelessWidget {
  final String log;
  const _LogLine({required this.log});

  @override
  Widget build(BuildContext context) {
    Color levelColor = AppTheme.textSecondary;
    FontWeight weight = FontWeight.normal;

    if (log.contains(' ERROR ')) {
      levelColor = AppTheme.error;
    } else if (log.contains(' WARN ')) {
      levelColor = AppTheme.warning;
    } else if (log.contains(' INFO ')) {
      levelColor = AppTheme.info;
    } else if (log.contains(' > ')) {
      levelColor = AppTheme.accentGreen;
      weight = FontWeight.w500;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: SelectableText(
        log,
        style: GoogleFonts.robotoMono(
          fontSize: 12.5,
          color: levelColor,
          fontWeight: weight,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PlayersTab extends StatelessWidget {
  final String serverId;
  final ServerModel server;

  const _PlayersTab({required this.serverId, required this.server});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServerProvider>(context);
    final players = provider.getOnlinePlayers(serverId);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Online Players',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${players.length} / ${server.maxPlayers}',
                  style: GoogleFonts.inter(
                      color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Tap menu to OP / Kick / Ban',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          if (players.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      server.status == ServerStatus.online
                          ? 'No players online yet'
                          : 'Server is offline',
                      style: GoogleFonts.inter(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: players.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final name = players[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.18),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Online'),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        switch (value) {
                          case 'op':
                            provider.sendCommand(serverId, 'op $name');
                            break;
                          case 'deop':
                            provider.sendCommand(serverId, 'deop $name');
                            break;
                          case 'kick':
                            provider.sendCommand(serverId, 'kick $name');
                            break;
                          case 'ban':
                            provider.sendCommand(serverId, 'ban $name');
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'op', child: Text('Make OP')),
                        PopupMenuItem(value: 'deop', child: Text('Remove OP')),
                        PopupMenuItem(value: 'kick', child: Text('Kick')),
                        PopupMenuItem(value: 'ban', child: Text('Ban')),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final ServerModel server;
  final ServerProvider provider;
  const _InfoTab({required this.server, required this.provider});

  @override
  Widget build(BuildContext context) {
    final installed = provider.getInstalledPlugins(server.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick actions
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.smart_toy,
                label: 'AI Builder',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiBuilderScreen(serverId: server.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.folder_outlined,
                label: 'Files',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FileBrowserScreen(
                        serverId: server.id,
                        serverName: server.name,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.extension,
                label: 'Plugins',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PluginsScreen(serverId: server.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Status',
          children: [
            _InfoRow('State', server.statusLabel, valueColor: server.statusColor),
            _InfoRow('Platform', server.platformLabel),
            _InfoRow('Software', '${server.softwareLabel} ${server.version}'),
            _InfoRow('MOTD', server.motd),
            if (server.publicAddress != null)
              _InfoRow('Public Address', server.publicAddress!),
            _InfoRow('Port', '${server.port}'),
            if (server.hasCustomWorld)
              _InfoRow('World', server.worldPath ?? 'Imported'),
            if (server.aiBuilderEnabled)
              _InfoRow('AI Builder', 'Enabled'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Resources',
          children: [
            _InfoRow(
              'RAM',
              '${server.usedRamGb.toStringAsFixed(1)} / ${server.maxRamGb.toStringAsFixed(1)} GB',
            ),
            _InfoRow('Players', '${server.onlinePlayers} / ${server.maxPlayers}'),
            _InfoRow('View Distance', '${server.viewDistance} chunks'),
            _InfoRow('Simulation', '${server.simulationDistance} chunks'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Gameplay',
          children: [
            _InfoRow('Gamemode', server.gamemode),
            _InfoRow('Difficulty', server.difficulty),
            _InfoRow('Online Mode', server.onlineMode ? 'On' : 'Off'),
            _InfoRow('PVP', server.pvp ? 'On' : 'Off'),
            _InfoRow('Hardcore', server.hardcore ? 'On' : 'Off'),
            _InfoRow('Whitelist', server.whitelistEnabled ? 'On' : 'Off'),
          ],
        ),
        if (installed.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Plugins (${installed.length})',
            children: installed
                .map((p) => _InfoRow(p.name, 'v${p.version}'))
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
