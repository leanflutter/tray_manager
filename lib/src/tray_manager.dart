import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

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
  TrayManager._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  /// The shared instance of [TrayManager].
  static final TrayManager instance = TrayManager._();

  final MethodChannel _channel = const MethodChannel('tray_manager');

  Map<int, MenuItem> _itemMap = {};
  int _lastItemId = 0;
  String _id = Uuid().v4();

  ObserverList<TrayListener> _listeners = ObserverList<TrayListener>();

  Future<void> _methodCallHandler(MethodCall call) async {
    for (final TrayListener listener in _listeners) {
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
          int id = call.arguments['id'];
          MenuItem menuItem = _itemMap[id]!;
          listener.onTrayMenuItemClick(menuItem);
          break;
      }
    }
  }

  bool get hasListeners {
    return _listeners.isNotEmpty;
  }

  void addListener(TrayListener listener) {
    _listeners.add(listener);
  }

  void removeListener(TrayListener listener) {
    _listeners.remove(listener);
  }

  Map<int, MenuItem> _indexItemMap(List<MenuItem> items) {
    final itemMap = <int, MenuItem>{};
    for (var item in items) {
      item.id = _lastItemId++;
      itemMap[item.id] = item;
      if (item.items.isNotEmpty) {
        final subItemMap = _indexItemMap(item.items);
        itemMap.addAll(subItemMap);
      }
    }
    return itemMap;
  }

  // Destroys the tray icon immediately.
  Future<void> destroy() async {
    await _channel.invokeMethod('destroy');
  }

  /// Sets the image associated with this tray icon.
  Future<void> setIcon(
    String iconPath, {
    bool isTemplate = false, // macOS only
  }) async {
    ByteData imageData = await rootBundle.load(iconPath);
    String base64Icon = base64Encode(imageData.buffer.asUint8List());

    final Map<String, dynamic> arguments = {
      'id': _id,
      'iconPath': path.joinAll([
        path.dirname(Platform.resolvedExecutable),
        'data/flutter_assets',
        iconPath,
      ]),
      'base64Icon': base64Icon,
      'isTemplate': isTemplate,
    };
    await _channel.invokeMethod('setIcon', arguments);
  }

  /// Sets the hover text for this tray icon.
  Future<void> setToolTip(String toolTip) async {
    final Map<String, dynamic> arguments = {
      'toolTip': toolTip,
    };
    await _channel.invokeMethod('setToolTip', arguments);
  }

  /// Sets the context menu for this icon.
  Future<void> setContextMenu(List<MenuItem> items) async {
    _itemMap = _indexItemMap(items);
    final Map<String, dynamic> arguments = {
      'items': items.map((e) => e.toJson()).toList(),
    };
    await _channel.invokeMethod('setContextMenu', arguments);
  }

  /// Pops up the context menu of the tray icon.
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

final trayManager = TrayManager.instance;
