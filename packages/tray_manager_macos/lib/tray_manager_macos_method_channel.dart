import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tray_manager_macos_platform_interface.dart';

/// An implementation of [TrayManagerMacosPlatform] that uses method channels.
class MethodChannelTrayManagerMacos extends TrayManagerMacosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tray_manager_macos');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
