import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../providers/server_provider.dart';
import '../models/server_model.dart';

class ServerSettingsScreen extends StatefulWidget {
  final String serverId;
  const ServerSettingsScreen({super.key, required this.serverId});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _motdController;
  late ServerModel _server;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<ServerProvider>(context, listen: false);
      _server = provider.servers.firstWhere((s) => s.id == widget.serverId);
      _nameController = TextEditingController(text: _server.name);
      _motdController = TextEditingController(text: _server.motd);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _motdController.dispose();
    super.dispose();
  }

  void _save() {
    final provider = Provider.of<ServerProvider>(context, listen: false);
    _server.name = _nameController.text.trim().isEmpty
        ? _server.name
        : _nameController.text.trim();
    _server.motd = _motdController.text.trim();
    provider.updateServer(_server);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_server.name),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'SAVE',
              style: GoogleFonts.inter(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // GENERAL
          _SectionHeader(title: 'GENERAL PROPERTIES', icon: Icons.settings),
          const SizedBox(height: 10),
          _Card(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('CS',
                        style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                title: const Text('Server Icon'),
                subtitle: const Text('Using default icon'),
                trailing: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Icon picker coming soon')),
                    );
                  },
                  child: const Text('Select'),
                ),
              ),
              const Divider(height: 24),
              Text('Server Name', style: _labelStyle),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'My Awesome Server'),
              ),
              const SizedBox(height: 16),
              Text('MOTD / Description', style: _labelStyle),
              const SizedBox(height: 6),
              TextField(
                controller: _motdController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Powered with ❤️ by CS LAUNCHER',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // PLATFORM
          _SectionHeader(title: 'PLATFORM', icon: Icons.devices),
          const SizedBox(height: 10),
          _Card(
            children: [
              Text('Who can join?', style: _labelStyle),
              const SizedBox(height: 10),
              Row(
                children: [
                  _PlatformChip(
                    label: 'Java',
                    selected: _server.platformType == PlatformType.java,
                    onTap: () => setState(() => _server.platformType = PlatformType.java),
                  ),
                  const SizedBox(width: 8),
                  _PlatformChip(
                    label: 'Bedrock',
                    selected: _server.platformType == PlatformType.bedrock,
                    onTap: () => setState(() {
                      _server.platformType = PlatformType.bedrock;
                      _server.software = ServerSoftware.powernukkitx;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _PlatformChip(
                    label: 'Both',
                    selected: _server.platformType == PlatformType.both,
                    onTap: () => setState(() => _server.platformType = PlatformType.both),
                  ),
                ],
              ),
              if (_server.platformType == PlatformType.both) ...[
                const SizedBox(height: 10),
                Text(
                  'Geyser + Floodgate will be used for cross-play.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // SOFTWARE
          _SectionHeader(title: 'SOFTWARE', icon: Icons.memory),
          const SizedBox(height: 10),
          _Card(
            children: [
              Text('Software', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<ServerSoftware>(
                value: _server.software,
                decoration: const InputDecoration(),
                dropdownColor: AppTheme.surface,
                items: ServerSoftware.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(_softwareName(s)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _server.software = v);
                },
              ),
              const SizedBox(height: 16),
              Text('Version', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _server.version,
                decoration: const InputDecoration(),
                dropdownColor: AppTheme.surface,
                items: const [
                  '1.21.3', '1.21.1', '1.21', '1.20.6', '1.20.4',
                  '1.20.1', '1.19.4', '1.18.2', '1.16.5',
                ].map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text(v + (v == '1.21.1' ? ' (Recommended)' : '')),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _server.version = v);
                },
              ),
              const SizedBox(height: 16),
              Text('Tunnel Region', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _server.tunnelRegion,
                decoration: const InputDecoration(),
                dropdownColor: AppTheme.surface,
                items: const ['EU', 'US', 'AS', 'Auto']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _server.tunnelRegion = v);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // PERFORMANCE
          _SectionHeader(title: 'PERFORMANCE', icon: Icons.bolt),
          const SizedBox(height: 10),
          _Card(
            children: [
              Text(
                'High view distance increases RAM and can cause lag on phones. Keep defaults if unsure.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              _SliderRow(
                label: 'View Distance',
                valueLabel: '${_server.viewDistance} chunks',
                value: _server.viewDistance.toDouble(),
                min: 2,
                max: 32,
                divisions: 30,
                onChanged: (v) => setState(() => _server.viewDistance = v.round()),
              ),
              _SliderRow(
                label: 'Simulation Distance',
                valueLabel: '${_server.simulationDistance} chunks',
                value: _server.simulationDistance.toDouble(),
                min: 2,
                max: 32,
                divisions: 30,
                onChanged: (v) => setState(() => _server.simulationDistance = v.round()),
              ),
              _SliderRow(
                label: 'Max RAM',
                valueLabel: '${_server.maxRamGb.toStringAsFixed(1)} GB',
                value: _server.maxRamGb,
                min: 0.5,
                max: 8.0,
                divisions: 15,
                onChanged: (v) => setState(() => _server.maxRamGb = v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // GAMEPLAY
          _SectionHeader(title: 'GAMEPLAY', icon: Icons.sports_esports),
          const SizedBox(height: 10),
          _Card(
            children: [
              _SwitchRow(
                title: 'Online Mode',
                subtitle: 'Require Mojang / Microsoft accounts',
                value: _server.onlineMode,
                onChanged: (v) => setState(() => _server.onlineMode = v),
              ),
              _SwitchRow(
                title: 'Whitelist',
                subtitle: 'Only allowed players can join',
                value: _server.whitelistEnabled,
                onChanged: (v) => setState(() => _server.whitelistEnabled = v),
              ),
              _SwitchRow(
                title: 'Allow Skins',
                subtitle: 'Custom player skins',
                value: _server.allowSkins,
                onChanged: (v) => setState(() => _server.allowSkins = v),
              ),
              _SwitchRow(
                title: 'PVP',
                subtitle: 'Player vs Player combat',
                value: _server.pvp,
                onChanged: (v) => setState(() => _server.pvp = v),
              ),
              _SwitchRow(
                title: 'Hardcore',
                subtitle: 'Ban on death',
                value: _server.hardcore,
                onChanged: (v) => setState(() => _server.hardcore = v),
              ),
              _SwitchRow(
                title: 'AI Builder',
                subtitle: 'Describe builds in chat — AI places blocks',
                value: _server.aiBuilderEnabled,
                onChanged: (v) => setState(() => _server.aiBuilderEnabled = v),
              ),
              const SizedBox(height: 8),
              Text('Difficulty', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _server.difficulty,
                decoration: const InputDecoration(),
                dropdownColor: AppTheme.surface,
                items: ['peaceful', 'easy', 'normal', 'hard']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _server.difficulty = v);
                },
              ),
              const SizedBox(height: 16),
              Text('Default Gamemode', style: _labelStyle),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _server.gamemode,
                decoration: const InputDecoration(),
                dropdownColor: AppTheme.surface,
                items: ['survival', 'creative', 'adventure', 'spectator']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _server.gamemode = v);
                },
              ),
              const SizedBox(height: 16),
              _SliderRow(
                label: 'Max Players',
                valueLabel: '${_server.maxPlayers}',
                value: _server.maxPlayers.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => setState(() => _server.maxPlayers = v.round()),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // DANGER
          _SectionHeader(title: 'DANGER ZONE', icon: Icons.warning_amber),
          const SizedBox(height: 10),
          _Card(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Delete Server',
                    style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w600)),
                subtitle: const Text('Permanently remove this server and its data'),
                trailing: const Icon(Icons.delete_outline, color: AppTheme.error),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: const Text('Delete server?'),
                      content: Text('"${_server.name}" will be permanently deleted.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete',
                              style: TextStyle(color: AppTheme.error)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && mounted) {
                    final provider =
                        Provider.of<ServerProvider>(context, listen: false);
                    await provider.deleteServer(_server.id);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _softwareName(ServerSoftware s) {
    switch (s) {
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
        return 'PowerNukkitX (Bedrock)';
      case ServerSoftware.pumpkin:
        return 'Pumpkin (Low RAM)';
    }
  }

  TextStyle get _labelStyle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary,
      );
}

class _PlatformChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PlatformChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen.withOpacity(0.15) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

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
        children: children,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary)),
            Text(valueLabel,
                style: GoogleFonts.inter(
                    color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
