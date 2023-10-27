import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:menu_base/menu_base.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shortid/shortid.dart';

import 'tray_listener.dart';

const kEventOnTrayIconMouseDown = 'onTrayIconMouseDown';
const kEventOnTrayIconMouseUp = 'onTrayIconMouseUp';
const kEventOnTrayIconRightMouseDown = 'onTrayIconRightMouseDown';
const kEventOnTrayIconRightMouseUp = 'onTrayIconRightMouseUp';
const kEventOnTrayMenuItemClick = 'onTrayMenuItemClick';
const kWindowsTaskbarCreated = 'onWindowsTaskbarCreated';

enum TrayIconPositon { left, right }

class TrayManager {
  TrayManager._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  /// The shared instance of [TrayManager].
  static final TrayManager instance = TrayManager._();

  final MethodChannel _channel = const MethodChannel('tray_manager');

  ObserverList<TrayListener> _listeners = ObserverList<TrayListener>();

  Menu? _menu;

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
          MenuItem? menuItem = _menu?.getMenuItemById(id);
          if (menuItem != null) {
            bool? oldChecked = menuItem.checked;
            if (menuItem.onClick != null) {
              menuItem.onClick!(menuItem);
            }
            listener.onTrayMenuItemClick(menuItem);

            bool? newChecked = menuItem.checked;
            if (oldChecked != newChecked) {
              await setContextMenu(_menu!);
            }
          }
          break;
        case kWindowsTaskbarCreated:
          listener.onWindowsTaskbarCreated();
          break;
      }
    }
  }

  /// Whether any listeners are currently registered.
  bool get hasListeners {
    return _listeners.isNotEmpty;
  }

  /// Register a closure to be called when the tray events.
  void addListener(TrayListener listener) {
    _listeners.add(listener);
  }

  /// Remove a previously registered closure from the list of closures that are
  /// notified when the tray events.
  void removeListener(TrayListener listener) {
    _listeners.remove(listener);
  }

  // Destroys the tray icon immediately.
  Future<void> destroy() async {
    await _channel.invokeMethod('destroy');
  }

  /// Sets the image associated with this tray icon.
  Future<void> setIcon(
    String iconPath, {
    bool isTemplate = false, // macOS only
    TrayIconPositon iconPosition = TrayIconPositon.left, // macOS only
  }) async {
    ByteData imageData = await rootBundle.load(iconPath);
    String base64Icon = base64Encode(imageData.buffer.asUint8List());

    final Map<String, dynamic> arguments = {
      "id": shortid.generate(),
      'iconPath': path.joinAll([
        path.dirname(Platform.resolvedExecutable),
        'data/flutter_assets',
        iconPath,
      ]),
      'base64Icon': base64Icon,
      'isTemplate': isTemplate,
      'iconPosition': iconPosition.name,
    };
    await _channel.invokeMethod('setIcon', arguments);
  }

  /// Sets the icon position of the tray icon.
  ///
  /// @platforms macos
  Future<void> setIconPosition(TrayIconPositon trayIconPositon) async {
    final arguments = <String, dynamic>{
      'iconPosition': trayIconPositon.name,
    };
    await _channel.invokeMethod('setIconPosition', arguments);
  }

  /// Sets the hover text for this tray icon.
  Future<void> setToolTip(String toolTip) async {
    final Map<String, dynamic> arguments = {
      'toolTip': toolTip,
    };
    await _channel.invokeMethod('setToolTip', arguments);
  }

  /// Sets the title for this tray icon.
  Future<void> setTitle(String title) async {
    final Map<String, dynamic> arguments = {
      'title': title,
    };
    await _channel.invokeMethod('setTitle', arguments);
  }

  /// Sets the context menu for this icon.
  Future<void> setContextMenu(Menu menu) async {
    _menu = menu;
    final Map<String, dynamic> arguments = {
      'menu': menu.toJson(),
    };
    await _channel.invokeMethod('setContextMenu', arguments);
  }

  /// Pops up the context menu of the tray icon.
  Future<void> popUpContextMenu() async {
    await _channel.invokeMethod('popUpContextMenu');
  }

  /// The bounds of this tray icon.
  Future<Rect?> getBounds() async {
    final Map<String, dynamic> arguments = {
      'devicePixelRatio': window.devicePixelRatio,
    };
    final Map<dynamic, dynamic>? resultData = await _channel.invokeMethod(
      'getBounds',
      arguments,
    );
    if (resultData == null) {
      return null;
    }
    return Rect.fromLTWH(
      resultData['x'],
      resultData['y'],
      resultData['width'],
      resultData['height'],
    );
  }
}

final trayManager = TrayManager.instance;
