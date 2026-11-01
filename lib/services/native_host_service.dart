import 'package:flutter/services.dart';

/// Flutter bridge to Android [ServerHostPlugin].
///
/// Currently returns skeleton responses until a JRE is embedded
/// and ProcessBuilder is wired in Kotlin.
class NativeHostService {
  static const _channel = MethodChannel('com.cslauncher.hosting/server');
  static const _console = EventChannel('com.cslauncher.hosting/console');

  static Stream<Map<dynamic, dynamic>> get consoleStream {
    return _console.receiveBroadcastStream().map((e) => Map<dynamic, dynamic>.from(e as Map));
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
      return {
        'ok': false,
        'mode': 'unsupported',
        'message': 'Native plugin not registered (run on Android device/emulator)',
      };
    } on PlatformException catch (e) {
      return {'ok': false, 'mode': 'error', 'message': e.message};
    }
  }

  static Future<bool> stopServer(String serverId) async {
    try {
      final r = await _channel.invokeMethod<bool>('stopServer', {'serverId': serverId});
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendCommand(String serverId, String command) async {
    try {
      final r = await _channel.invokeMethod<bool>('sendCommand', {
        'serverId': serverId,
        'command': command,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isRunning(String serverId) async {
    try {
      final r = await _channel.invokeMethod<bool>('isRunning', {'serverId': serverId});
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getServerDir(String serverId) async {
    try {
      return await _channel.invokeMethod<String>('getServerDir', {'serverId': serverId});
    } catch (_) {
      return null;
    }
  }
}
