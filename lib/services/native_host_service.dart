import 'package:flutter/services.dart';

/// Bridge to Android — real bore.pub when binary is installed.
class NativeHostService {
  static const _channel = MethodChannel('com.cslauncher.hosting/server');
  static const _console = EventChannel('com.cslauncher.hosting/console');

  static Stream<Map<dynamic, dynamic>> get consoleStream {
    return _console
        .receiveBroadcastStream()
        .map((e) => Map<dynamic, dynamic>.from(e as Map));
  }

  /// Real tunnel: bore local → bore.pub (or custom host)
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
      return {
        'ok': false,
        'mode': 'unsupported',
        'message': 'Only on Android device build',
      };
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

  static Future<bool> hasBoreBinary() async {
    try {
      return await _channel.invokeMethod<bool>('hasBoreBinary') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> startServer({
    required String serverId,
    required String jarPath,
    required int maxRamMb,
    required int port,
    required String workingDir,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('startServer', {
        'serverId': serverId,
        'jarPath': jarPath,
        'maxRamMb': maxRamMb,
        'port': port,
        'workingDir': workingDir,
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

  static Future<String?> getServerDir(String serverId) async {
    try {
      return await _channel
          .invokeMethod<String>('getServerDir', {'serverId': serverId});
    } catch (_) {
      return null;
    }
  }
}
