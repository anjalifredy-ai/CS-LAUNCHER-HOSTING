import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../theme/app_theme.dart';
import '../providers/server_provider.dart';
import '../models/server_model.dart';

class CreateServerScreen extends StatefulWidget {
  const CreateServerScreen({super.key});

  @override
  State<CreateServerScreen> createState() => _CreateServerScreenState();
}

class _CreateServerScreenState extends State<CreateServerScreen> {
  final _nameController = TextEditingController(text: 'My Server');
  ServerSoftware _software = ServerSoftware.paper;
  String _version = '1.21.1';
  double _maxRam = 2.0;
  int _maxPlayers = 20;
  bool _onlineMode = true;
  bool _bedrockSupport = false;
  GameTemplate _template = GameTemplate.survival;
  String _tunnelRegion = 'EU';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    final name = _nameController.text.trim().isEmpty
        ? 'My Server'
        : _nameController.text.trim();

    final id = 'srv-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';

    String gamemode = 'survival';
    if (_template == GameTemplate.creative) gamemode = 'creative';

    final server = ServerModel(
      id: id,
      name: name,
      software: _software,
      version: _version,
      maxRamGb: _maxRam,
      maxPlayers: _maxPlayers,
      onlineMode: _onlineMode,
      bedrockSupport: _bedrockSupport,
      template: _template,
      tunnelRegion: _tunnelRegion,
      gamemode: gamemode,
      motd: 'Powered with ❤️ by CS LAUNCHER',
    );

    final provider = Provider.of<ServerProvider>(context, listen: false);
    provider.createServer(server);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server "$name" created!'),
        action: SnackBarAction(
          label: 'START',
          textColor: AppTheme.primaryGreen,
          onPressed: () => provider.startServer(id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Create Server')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'One-Click Setup',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a template or custom software. Free public tunnel included.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),

          Text('Game Mode Template', style: _label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Survival', GameTemplate.survival, Icons.terrain),
              _chip('Creative', GameTemplate.creative, Icons.brush),
              _chip('SkyBlock', GameTemplate.skyblock, Icons.cloud),
              _chip('OneBlock', GameTemplate.oneblock, Icons.crop_square),
              _chip('AcidIsland', GameTemplate.acidisland, Icons.water),
              _chip('CaveBlock', GameTemplate.caveblock, Icons.landscape),
              _chip('Custom', GameTemplate.none, Icons.tune),
            ],
          ),
          const SizedBox(height: 20),

          Text('Server Name', style: _label),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Survival with friends'),
          ),
          const SizedBox(height: 16),

          Text('Software', style: _label),
          const SizedBox(height: 6),
          DropdownButtonFormField<ServerSoftware>(
            value: _software,
            decoration: const InputDecoration(),
            dropdownColor: AppTheme.surface,
            items: [
              DropdownMenuItem(value: ServerSoftware.paper, child: Text('Paper (Recommended)')),
              DropdownMenuItem(value: ServerSoftware.purpur, child: Text('Purpur')),
              DropdownMenuItem(value: ServerSoftware.spigot, child: Text('Spigot')),
              DropdownMenuItem(value: ServerSoftware.fabric, child: Text('Fabric (Mods)')),
              DropdownMenuItem(value: ServerSoftware.neoforge, child: Text('NeoForge (Mods)')),
              DropdownMenuItem(value: ServerSoftware.forge, child: Text('Forge')),
              DropdownMenuItem(value: ServerSoftware.vanilla, child: Text('Vanilla')),
              DropdownMenuItem(value: ServerSoftware.powernukkitx, child: Text('PowerNukkitX (Native Bedrock)')),
              DropdownMenuItem(value: ServerSoftware.pumpkin, child: Text('Pumpkin (Low RAM)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _software = v);
            },
          ),
          const SizedBox(height: 16),

          Text('Version', style: _label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _version,
            decoration: const InputDecoration(),
            dropdownColor: AppTheme.surface,
            items: const [
              '1.21.3', '1.21.1', '1.21', '1.20.6', '1.20.4', '1.20.1', '1.19.4', '1.18.2', '1.16.5',
            ].map((v) => DropdownMenuItem(
              value: v,
              child: Text(v + (v == '1.21.1' ? ' (Recommended)' : '')),
            )).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _version = v);
            },
          ),
          const SizedBox(height: 16),

          Text('Tunnel Region', style: _label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _tunnelRegion,
            decoration: const InputDecoration(),
            dropdownColor: AppTheme.surface,
            items: const ['EU', 'US', 'AS', 'Auto']
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _tunnelRegion = v);
            },
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max RAM', style: _label),
              Text('${_maxRam.toStringAsFixed(1)} GB',
                  style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _maxRam,
            min: 0.5,
            max: 8.0,
            divisions: 15,
            label: '${_maxRam.toStringAsFixed(1)} GB',
            onChanged: (v) => setState(() => _maxRam = v),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Players', style: _label),
              Text('$_maxPlayers',
                  style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _maxPlayers.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: '$_maxPlayers',
            onChanged: (v) => setState(() => _maxPlayers = v.round()),
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Online Mode'),
            subtitle: const Text('Require official Minecraft accounts'),
            value: _onlineMode,
            activeColor: AppTheme.primaryGreen,
            onChanged: (v) => setState(() => _onlineMode = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bedrock Cross-Play'),
            subtitle: const Text('Geyser + Floodgate (Java + Bedrock together)'),
            value: _bedrockSupport,
            activeColor: AppTheme.primaryGreen,
            onChanged: (v) => setState(() => _bedrockSupport = v),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _FeatureRow(Icons.flash_on, 'Easy One-Click Setup'),
                _FeatureRow(Icons.public, 'No Portforwarding'),
                _FeatureRow(Icons.favorite, '100% Free & Unlimited'),
                _FeatureRow(Icons.devices, 'Java + Bedrock Cross-Play'),
                _FeatureRow(Icons.link, 'Free Public Domain (bore.pub)'),
                _FeatureRow(Icons.extension, 'Plugins & Mods Support'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _create,
              child: Text('CREATE SERVER',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _chip(String label, GameTemplate value, IconData icon) {
    final selected = _template == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? AppTheme.primaryGreen : AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _template = value),
      selectedColor: AppTheme.primaryGreen.withOpacity(0.18),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? AppTheme.primaryGreen : AppTheme.textSecondary,
      ),
      backgroundColor: AppTheme.surface,
      side: BorderSide(color: selected ? AppTheme.primaryGreen : Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  TextStyle get _label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary,
      );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
