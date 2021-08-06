
import 'dart:async';

import 'package:flutter/services.dart';

class TrayManager {
  static const MethodChannel _channel =
      const MethodChannel('tray_manager');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
