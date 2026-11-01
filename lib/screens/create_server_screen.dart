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

    final server = ServerModel(
      id: id,
      name: name,
      software: _software,
      version: _version,
      maxRamGb: _maxRam,
      maxPlayers: _maxPlayers,
      onlineMode: _onlineMode,
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
      appBar: AppBar(
        title: const Text('Create Server'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Easy One-Click Setup',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose software, version and basic settings. You can change everything later.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Name
          Text('Server Name', style: _label),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Survival with friends',
            ),
          ),
          const SizedBox(height: 20),

          // Software
          Text('Software', style: _label),
          const SizedBox(height: 6),
          DropdownButtonFormField<ServerSoftware>(
            value: _software,
            decoration: const InputDecoration(),
            dropdownColor: AppTheme.surface,
            items: ServerSoftware.values.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(_name(s)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _software = v);
            },
          ),
          const SizedBox(height: 16),

          // Version
          Text('Version', style: _label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _version,
            decoration: const InputDecoration(),
            dropdownColor: AppTheme.surface,
            items: const [
              '1.21.3',
              '1.21.1',
              '1.21',
              '1.20.6',
              '1.20.4',
              '1.20.1',
              '1.19.4',
              '1.18.2',
              '1.16.5',
            ].map((v) {
              return DropdownMenuItem(
                value: v,
                child: Text(v + (v == '1.21.1' ? ' (Recommended)' : '')),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _version = v);
            },
          ),
          const SizedBox(height: 20),

          // RAM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max RAM', style: _label),
              Text(
                '${_maxRam.toStringAsFixed(1)} GB',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          const SizedBox(height: 8),

          // Max Players
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Players', style: _label),
              Text(
                '$_maxPlayers',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          const SizedBox(height: 12),

          // Online Mode
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Online Mode'),
            subtitle: const Text('Require official Minecraft accounts'),
            value: _onlineMode,
            activeColor: AppTheme.primaryGreen,
            onChanged: (v) => setState(() => _onlineMode = v),
          ),

          const SizedBox(height: 32),

          // Features reminder
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
                _FeatureRow(Icons.dashboard, 'Remote Dashboard'),
                _FeatureRow(Icons.link, 'Free Public Domain (bore.pub)'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _create,
              child: Text(
                'CREATE SERVER',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _name(ServerSoftware s) {
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
      case ServerSoftware.optifine:
        return 'OptiFine';
    }
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
