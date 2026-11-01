import 'package:flutter/services.dart';

/// Android native bridge — MineServe-style jar + bore + java.
class NativeHostService {
  static const _channel = MethodChannel('com.cslauncher.hosting/server');
  static const _console = EventChannel('com.cslauncher.hosting/console');

  static Stream<Map<dynamic, dynamic>> get consoleStream {
    return _console
        .receiveBroadcastStream()
        .map((e) => Map<dynamic, dynamic>.from(e as Map));
  }

  /// Download Paper jar + eula into files/servers/<id>/
  static Future<Map<String, dynamic>> prepareServer({
    required String serverId,
    required String jarUrl,
    String version = '1.21.1',
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('prepareServer', {
        'serverId': serverId,
        'jarUrl': jarUrl,
        'version': version,
      });
      return Map<String, dynamic>.from(result ?? {});
    } on MissingPluginException {
      return {'ok': false, 'message': 'Android only'};
    } on PlatformException catch (e) {
      return {'ok': false, 'message': e.message};
    }
  }

  static Future<Map<String, dynamic>> startTunnel({
    required String serverId,
    int localPort = 25565,
    String toHost = 'bore.pub',
    String? secret,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('startTunnel', {
        'serverId': serverId,
        'localPort': localPort,
        'toHost': toHost,
        if (secret != null) 'secret': secret,
      });
      return Map<String, dynamic>.from(result ?? {});
    } on MissingPluginException {
      return {'ok': false, 'mode': 'unsupported'};
    } on PlatformException catch (e) {
      return {'ok': false, 'mode': 'error', 'message': e.message};
    }
  }

  static Future<bool> stopTunnel(String serverId) async {
    try {
      return await _channel
              .invokeMethod<bool>('stopTunnel', {'serverId': serverId}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> startServer({
    required String serverId,
    String? jarPath,
    int maxRamMb = 1024,
    String? workingDir,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('startServer', {
        'serverId': serverId,
        if (jarPath != null) 'jarPath': jarPath,
        'maxRamMb': maxRamMb,
        if (workingDir != null) 'workingDir': workingDir,
      });
      return Map<String, dynamic>.from(result ?? {});
    } on MissingPluginException {
      return {'ok': false, 'mode': 'unsupported'};
    } on PlatformException catch (e) {
      return {'ok': false, 'mode': 'error', 'message': e.message};
    }
  }

  static Future<bool> stopServer(String serverId) async {
    try {
      return await _channel
              .invokeMethod<bool>('stopServer', {'serverId': serverId}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasJava() async {
    try {
      return await _channel.invokeMethod<bool>('hasJava') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getServerDir(String serverId) async {
    try {
      return await _channel
          .invokeMethod<String>('getServerDir', {'serverId': serverId});
    } catch (_) {
      return null;
    }
  }
}
