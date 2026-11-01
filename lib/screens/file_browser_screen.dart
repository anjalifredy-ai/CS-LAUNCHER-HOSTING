import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Simulated file browser for server folder structure.
/// Real version will use path_provider + real filesystem.
class FileBrowserScreen extends StatefulWidget {
  final String serverId;
  final String serverName;

  const FileBrowserScreen({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  String _currentPath = '/';
  final List<String> _history = ['/'];

  // Simulated tree
  final Map<String, List<_FsEntry>> _tree = {
    '/': [
      _FsEntry('world', true, '~48 MB'),
      _FsEntry('world_nether', true, '~12 MB'),
      _FsEntry('world_the_end', true, '~8 MB'),
      _FsEntry('plugins', true, '—'),
      _FsEntry('mods', true, '—'),
      _FsEntry('config', true, '—'),
      _FsEntry('logs', true, '—'),
      _FsEntry('server.jar', false, '42.1 MB'),
      _FsEntry('server.properties', false, '2.4 KB'),
      _FsEntry('eula.txt', false, '128 B'),
      _FsEntry('ops.json', false, '256 B'),
      _FsEntry('whitelist.json', false, '64 B'),
      _FsEntry('banned-players.json', false, '32 B'),
      _FsEntry('bukkit.yml', false, '1.1 KB'),
      _FsEntry('spigot.yml', false, '3.2 KB'),
      _FsEntry('paper-global.yml', false, '4.8 KB'),
    ],
    '/plugins': [
      _FsEntry('EssentialsX.jar', false, '3.2 MB'),
      _FsEntry('Vault.jar', false, '412 KB'),
      _FsEntry('LuckPerms.jar', false, '1.8 MB'),
      _FsEntry('Essentials', true, '—'),
      _FsEntry('LuckPerms', true, '—'),
    ],
    '/plugins/Essentials': [
      _FsEntry('config.yml', false, '18 KB'),
      _FsEntry('worth.yml', false, '4 KB'),
    ],
    '/mods': [
      _FsEntry('(empty — Fabric/NeoForge only)', false, ''),
    ],
    '/world': [
      _FsEntry('level.dat', false, '8 KB'),
      _FsEntry('region', true, '—'),
      _FsEntry('data', true, '—'),
      _FsEntry('playerdata', true, '—'),
      _FsEntry('datapacks', true, '—'),
    ],
    '/logs': [
      _FsEntry('latest.log', false, '256 KB'),
      _FsEntry('2026-11-01-1.log.gz', false, '48 KB'),
    ],
    '/config': [
      _FsEntry('paper-world-defaults.yml', false, '2 KB'),
    ],
  };

  List<_FsEntry> get _entries {
    return _tree[_currentPath] ??
        [_FsEntry('(empty)', false, '')];
  }

  void _open(_FsEntry e) {
    if (!e.isDir) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${e.name} — viewer coming in native build'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final next = _currentPath == '/' ? '/${e.name}' : '$_currentPath/${e.name}';
    setState(() {
      _currentPath = next;
      _history.add(next);
    });
  }

  void _up() {
    if (_history.length <= 1) return;
    setState(() {
      _history.removeLast();
      _currentPath = _history.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              widget.serverName,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New folder',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create folder (native)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload file (native)')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Path bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppTheme.surface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: _history.length > 1 ? _up : null,
                  color: AppTheme.primaryGreen,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      color: AppTheme.accentGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Quick chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                _QuickChip('Root', '/', Icons.home),
                _QuickChip('World', '/world', Icons.public),
                _QuickChip('Plugins', '/plugins', Icons.extension),
                _QuickChip('Mods', '/mods', Icons.inventory_2),
                _QuickChip('Logs', '/logs', Icons.article),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = _entries[i];
                return ListTile(
                  leading: Icon(
                    e.isDir ? Icons.folder : Icons.insert_drive_file_outlined,
                    color: e.isDir ? AppTheme.primaryGreen : AppTheme.textMuted,
                  ),
                  title: Text(
                    e.name,
                    style: GoogleFonts.inter(
                      fontWeight: e.isDir ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: e.size.isNotEmpty
                      ? Text(e.size, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted))
                      : null,
                  trailing: e.isDir
                      ? const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted)
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (v) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$v ${e.name}')),
                            );
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'View', child: Text('View / Edit')),
                            PopupMenuItem(value: 'Download', child: Text('Download')),
                            PopupMenuItem(value: 'Delete', child: Text('Delete')),
                          ],
                        ),
                  onTap: () => _open(e),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _QuickChip(String label, String path, IconData icon) {
    final selected = _currentPath == path;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppTheme.primaryGreen : AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _currentPath = path;
            if (!_history.contains(path)) _history.add(path);
          });
        },
        selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
        backgroundColor: AppTheme.card,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppTheme.primaryGreen : AppTheme.textSecondary,
        ),
        side: BorderSide(color: selected ? AppTheme.primaryGreen : Colors.transparent),
      ),
    );
  }
}

class _FsEntry {
  final String name;
  final bool isDir;
  final String size;
  _FsEntry(this.name, this.isDir, this.size);
}
