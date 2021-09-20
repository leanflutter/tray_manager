import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path/path.dart' as path;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'menu_item.dart';
import 'tray_listener.dart';

const kEventOnTrayIconMouseDown = 'onTrayIconMouseDown';
const kEventOnTrayIconMouseUp = 'onTrayIconMouseUp';
const kEventOnTrayIconRightMouseDown = 'onTrayIconRightMouseDown';
const kEventOnTrayIconRightMouseUp = 'onTrayIconRightMouseUp';
const kEventOnTrayMenuItemClick = 'onTrayMenuItemClick';

class TrayManager {
  TrayManager._();

  /// The shared instance of [TrayManager].
  static final TrayManager instance = TrayManager._();

  final MethodChannel _channel = const MethodChannel('tray_manager');

  bool _inited = false;
  List<MenuItem> _itemList = [];

  ObserverList<TrayListener>? _listeners = ObserverList<TrayListener>();

  void _init() {
    _channel.setMethodCallHandler(_methodCallHandler);
    _inited = true;
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    if (_listeners == null) return;

    final List<TrayListener> localListeners =
        List<TrayListener>.from(_listeners!);
    for (final TrayListener listener in localListeners) {
      if (_listeners!.contains(listener)) {
        switch (call.method) {
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
          case kEventOnTrayMenuItemClick:
            String identifier = call.arguments['identifier'];
            MenuItem menuItem = _itemList.firstWhere(
              (e) => e.identifier == identifier,
            );
            listener.onTrayMenuItemClick(menuItem);
            break;
        }
      }
    }
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

  Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // Destroys the tray icon immediately.
  Future<void> destroy() async {
    await _channel.invokeMethod('destroy');
  }

  Future<void> setIcon(String iconPath) async {
    if (!_inited) this._init();

    ByteData imageData = await rootBundle.load(iconPath);
    String base64Icon = base64Encode(imageData.buffer.asUint8List());

    final Map<String, dynamic> arguments = {
      'iconPath': path.joinAll([
        path.dirname(Platform.resolvedExecutable),
        'data/flutter_assets',
        iconPath,
      ]),
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

  Future<void> setContextMenu(List<MenuItem> items) async {
    _itemList = [];
    for (var item in items) {
      _itemList.add(item);
      if (item.items.isNotEmpty) {
        for (var subitem in item.items) {
          _itemList.add(subitem);
        }
      }
    }
    final Map<String, dynamic> arguments = {
      'items': items.map((e) => e.toJson()).toList(),
    };
    await _channel.invokeMethod('setContextMenu', arguments);
  }

  Future<void> popUpContextMenu() async {
    await _channel.invokeMethod('popUpContextMenu');
  }

  Future<Rect> getBounds() async {
    final Map<String, dynamic> arguments = {
      'devicePixelRatio': window.devicePixelRatio,
    };
    final Map<dynamic, dynamic> resultData =
        await _channel.invokeMethod('getBounds', arguments);
    return Rect.fromLTWH(
      resultData['x'],
      resultData['y'],
      resultData['width'],
      resultData['height'],
    );
  }
}
