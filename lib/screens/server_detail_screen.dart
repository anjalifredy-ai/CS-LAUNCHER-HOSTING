import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../providers/server_provider.dart';
import '../models/server_model.dart';
import 'server_settings_screen.dart';

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

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(server.name),
            actions: [
              // Quick Start / Stop from app bar
              if (isOnline)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.error),
                  tooltip: 'Stop Server',
                  onPressed: () => provider.stopServer(server.id),
                )
              else
                IconButton(
                  icon: const Icon(Icons.play_circle_outline, color: AppTheme.primaryGreen),
                  tooltip: 'Start Server',
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
              // ===== CONSOLE TAB =====
              Column(
                children: [
                  // Live output header
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
                  // Logs
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
                  // Command input
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(
                        top: BorderSide(color: AppTheme.surfaceLight),
                      ),
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
                              color: isOnline
                                  ? AppTheme.primaryGreen
                                  : AppTheme.surfaceLight,
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

              // ===== PLAYERS TAB =====
              _PlayersTab(serverId: server.id, server: server),

              // ===== INFO TAB =====
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
      // User typed command
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
              Text(
                'Online Players',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${players.length} / ${server.maxPlayers}',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the menu to OP / Kick / Ban players',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (players.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted),
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
                    title: Text(
                      name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Online'),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        switch (value) {
                          case 'op':
                            provider.sendCommand(serverId, 'op $name');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opped $name')),
                            );
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
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'op',
                          child: Row(
                            children: [
                              Icon(Icons.shield, size: 18, color: AppTheme.primaryGreen),
                              SizedBox(width: 10),
                              Text('Make OP'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'deop',
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Remove OP'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'kick',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18, color: AppTheme.warning),
                              SizedBox(width: 10),
                              Text('Kick'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'ban',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 18, color: AppTheme.error),
                              SizedBox(width: 10),
                              Text('Ban'),
                            ],
                          ),
                        ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Status',
          children: [
            _InfoRow('State', server.statusLabel, valueColor: server.statusColor),
            _InfoRow('Software', '${server.softwareLabel} ${server.version}'),
            _InfoRow('MOTD', server.motd),
            if (server.publicAddress != null)
              _InfoRow('Public Address', server.publicAddress!),
            _InfoRow('Port', '${server.port}'),
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
            if (server.status == ServerStatus.online)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (server.usedRamGb / server.maxRamGb).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                    minHeight: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Gameplay',
          children: [
            _InfoRow('Max Players', '${server.maxPlayers}'),
            _InfoRow('Online Mode', server.onlineMode ? 'ON' : 'OFF'),
            _InfoRow('Allow Skins', server.allowSkins ? 'Yes' : 'No'),
            _InfoRow('PVP', server.pvp ? 'Enabled' : 'Disabled'),
            _InfoRow('Hardcore', server.hardcore ? 'Yes' : 'No'),
            _InfoRow('Difficulty', server.difficulty),
            _InfoRow('Gamemode', server.gamemode),
            _InfoRow('View Distance', '${server.viewDistance} chunks'),
          ],
        ),
        const SizedBox(height: 24),
        if (server.status == ServerStatus.online)
          ElevatedButton(
            onPressed: () => provider.stopServer(server.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP SERVER'),
          )
        else
          ElevatedButton.icon(
            onPressed: () => provider.startServer(server.id),
            icon: const Icon(Icons.play_arrow),
            label: const Text('START SERVER'),
          ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
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
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
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
