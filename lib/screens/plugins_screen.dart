import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../providers/server_provider.dart';
import '../models/plugin_model.dart';

class PluginsScreen extends StatefulWidget {
  final String serverId;
  const PluginsScreen({super.key, required this.serverId});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  String _search = '';
  String _filter = 'All'; // All, Installed, Utility, Admin, etc.

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        final allPlugins = provider.availablePlugins;
        final installedIds = provider.getInstalledPluginIds(widget.serverId);

        var filtered = allPlugins.where((p) {
          final matchesSearch = _search.isEmpty ||
              p.name.toLowerCase().contains(_search.toLowerCase()) ||
              p.description.toLowerCase().contains(_search.toLowerCase()) ||
              p.author.toLowerCase().contains(_search.toLowerCase());

          if (!matchesSearch) return false;

          if (_filter == 'Installed') {
            return installedIds.contains(p.id);
          } else if (_filter != 'All') {
            return p.category == _filter;
          }
          return true;
        }).toList();

        // Sort: installed first, then by downloads
        filtered.sort((a, b) {
          final aInst = installedIds.contains(a.id);
          final bInst = installedIds.contains(b.id);
          if (aInst && !bInst) return -1;
          if (!aInst && bInst) return 1;
          return b.downloads.compareTo(a.downloads);
        });

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Plugins'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '${installedIds.length} installed',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search plugins...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Filter chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'All',
                      onTap: () => setState(() => _filter = 'All'),
                    ),
                    _FilterChip(
                      label: 'Installed',
                      selected: _filter == 'Installed',
                      onTap: () => setState(() => _filter = 'Installed'),
                    ),
                    _FilterChip(
                      label: 'Utility',
                      selected: _filter == 'Utility',
                      onTap: () => setState(() => _filter = 'Utility'),
                    ),
                    _FilterChip(
                      label: 'Admin',
                      selected: _filter == 'Admin',
                      onTap: () => setState(() => _filter = 'Admin'),
                    ),
                    _FilterChip(
                      label: 'World',
                      selected: _filter == 'World',
                      onTap: () => setState(() => _filter = 'World'),
                    ),
                    _FilterChip(
                      label: 'Gameplay',
                      selected: _filter == 'Gameplay',
                      onTap: () => setState(() => _filter = 'Gameplay'),
                    ),
                    _FilterChip(
                      label: 'API',
                      selected: _filter == 'API',
                      onTap: () => setState(() => _filter = 'API'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Plugin list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No plugins found',
                          style: GoogleFonts.inter(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final plugin = filtered[index];
                          final isInstalled = installedIds.contains(plugin.id);
                          return _PluginCard(
                            plugin: plugin,
                            isInstalled: isInstalled,
                            onInstall: () async {
                              await provider.installPlugin(
                                  widget.serverId, plugin.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${plugin.name} installed!'),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              }
                            },
                            onUninstall: () async {
                              await provider.uninstallPlugin(
                                  widget.serverId, plugin.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${plugin.name} uninstalled'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryGreen,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppTheme.primaryGreen : AppTheme.textSecondary,
        ),
        backgroundColor: AppTheme.surface,
        side: BorderSide(
          color: selected ? AppTheme.primaryGreen : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _PluginCard extends StatelessWidget {
  final PluginModel plugin;
  final bool isInstalled;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const _PluginCard({
    required this.plugin,
    required this.isInstalled,
    required this.onInstall,
    required this.onUninstall,
  });

  String _formatDownloads(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: isInstalled
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.extension, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plugin.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isInstalled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'INSTALLED',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${plugin.author} · v${plugin.version}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plugin.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plugin.category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.download_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 3),
              Text(
                _formatDownloads(plugin.downloads),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              if (isInstalled)
                OutlinedButton(
                  onPressed: onUninstall,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Text('Remove'),
                )
              else
                ElevatedButton(
                  onPressed: onInstall,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Text('Install'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
