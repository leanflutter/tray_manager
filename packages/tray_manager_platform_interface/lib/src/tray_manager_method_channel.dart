import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager_platform_interface/src/tray_manager_platform_interface.dart';

/// An implementation of [TrayManagerPlatform] that uses method channels.
class MethodChannelTrayManager extends TrayManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tray_manager');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
