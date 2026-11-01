import 'dart:convert';
import 'package:http/http.dart' as http;

/// PaperMC downloads (MineServe-style one-tap jar).
class PaperApiService {
  static const _base = 'https://api.papermc.io/v2/projects/paper';

  /// Returns direct jar URL for [version] (e.g. 1.21.1), latest build.
  static Future<String?> latestJarUrl(String version) async {
    try {
      final buildsRes = await http.get(
        Uri.parse('$_base/versions/$version/builds'),
      );
      if (buildsRes.statusCode != 200) return null;
      final buildsJson = jsonDecode(buildsRes.body) as Map<String, dynamic>;
      final builds = buildsJson['builds'] as List?;
      if (builds == null || builds.isEmpty) return null;

      final latest = builds.last as Map<String, dynamic>;
      final build = latest['build'];
      final downloads = latest['downloads'] as Map<String, dynamic>?;
      final app = downloads?['application'] as Map<String, dynamic>?;
      final name = app?['name'] as String?;
      if (build == null || name == null) return null;

      return '$_base/versions/$version/builds/$build/downloads/$name';
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> listVersions() async {
    try {
      final res = await http.get(Uri.parse(_base));
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final versions = json['versions'] as List?;
      return versions?.map((e) => e.toString()).toList().reversed.toList() ??
          [];
    } catch (_) {
      return [];
    }
  }
}
