import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'menu_item.dart';
import 'tray_listener.dart';

const kEventOnTrayIconMouseDown = 'onTrayIconMouseDown';
const kEventOnTrayIconMouseUp = 'onTrayIconMouseUp';
const kEventOnTrayIconRightMouseDown = 'onTrayIconRightMouseDown';
const kEventOnTrayIconRightMouseUp = 'onTrayIconRightMouseUp';

class TrayManager {
  TrayManager._();

  /// The shared instance of [TrayManager].
  static final TrayManager instance = TrayManager._();

  final MethodChannel _channel = const MethodChannel('tray_manager');

  bool _inited = false;
  List<MenuItem> _menuItemList = [];

  ObserverList<TrayListener>? _listeners = ObserverList<TrayListener>();

  void _init() {
    _channel.setMethodCallHandler(_methodCallHandler);
    _inited = true;
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    notifyListeners(call.method);
  }

  bool get hasListeners {
    return _listeners!.isNotEmpty;
  }

  void addListener(TrayListener listener) {
    _listeners!.add(listener);
  }

  void removeListener(TrayListener listener) {
    _listeners!.remove(listener);
  }

  void notifyListeners(String? method, [dynamic data]) {
    if (_listeners == null) return;

    final List<TrayListener> localListeners =
        List<TrayListener>.from(_listeners!);
    for (final TrayListener listener in localListeners) {
      if (_listeners!.contains(listener)) {
        switch (method) {
          case kEventOnTrayIconMouseDown:
            listener.onTrayIconMouseDown();
            break;
          case kEventOnTrayIconMouseUp:
            listener.onTrayIconMouseUp();
            break;
          case kEventOnTrayIconRightMouseDown:
            listener.onTrayIconRightMouseDown();
            break;
          case kEventOnTrayIconRightMouseUp:
            listener.onTrayIconRightMouseUp();
            break;
        }
      }
    }
  }

  Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<Rect> getFrame() async {
    final Map<dynamic, dynamic> resultData =
        await _channel.invokeMethod('getFrame');

    return Rect.fromLTWH(
      resultData['origin_x'],
      resultData['origin_y'],
      resultData['size_width'],
      resultData['size_height'],
    );
  }

  Future<void> setIcon(String icon) async {
    if (!_inited) this._init();

    ByteData imageData = await rootBundle.load(icon);
    String base64Icon = base64Encode(imageData.buffer.asUint8List());

    final Map<String, dynamic> arguments = {
      'base64Icon': base64Icon,
    };
    await _channel.invokeMethod('setIcon', arguments);
  }

  Future<void> setToolTip(String toolTip) async {
    final Map<String, dynamic> arguments = {
      'toolTip': toolTip,
    };
    await _channel.invokeMethod('setToolTip', arguments);
  }

  Future<void> setContextMenu(List<MenuItem> menuItems) async {
    final Map<String, dynamic> arguments = {
      'menuItems': menuItems.map((e) => e.toJson()).toList(),
    };
    await _channel.invokeMethod('setContextMenu', arguments);
  }

  Future<void> popUpContextMenu() async {
    await _channel.invokeMethod('popUpContextMenu');
  }
}
