import 'dart:async';
import 'dart:ui' show Rect, Size;

import 'package:nativeapi/nativeapi.dart' as nativeapi;
import 'package:tray_manager/src/menu.dart';
import 'package:tray_manager/src/tray_listener.dart';

enum TrayIconPosition { left, right }

/// The pre-nativeapi `TrayManager` on top of a single [nativeapi.TrayIcon],
/// for code that has not moved to the native API yet.
class TrayManager {
  TrayManager._();

  /// The shared instance of [TrayManager].
  static final TrayManager instance = TrayManager._();

  nativeapi.TrayIcon? _trayIcon;
  nativeapi.Image? _icon;
  Menu? _menu;
  NativeMenuBinding? _menuBinding;
  final List<TrayListener> _listeners = <TrayListener>[];
  nativeapi.ListenerId? _trayListenerId;

  nativeapi.TrayIcon get _ensureTrayIcon {
    var trayIcon = _trayIcon;
    if (trayIcon == null) {
      trayIcon = nativeapi.TrayIcon.create();
      if (trayIcon == null) {
        throw StateError('Unable to create the tray icon');
      }
      trayIcon.setVisible(true);
      _trayIcon = trayIcon;
    }
    _wireTrayEvents(trayIcon);
    return trayIcon;
  }

  bool get isSupported => nativeapi.TrayManager.instance.isSupported();

  bool get hasListeners => _listeners.isNotEmpty;

  void addListener(TrayListener listener) {
    if (_listeners.contains(listener)) {
      return;
    }
    _listeners.add(listener);
    final trayIcon = _trayIcon;
    if (trayIcon != null) {
      _wireTrayEvents(trayIcon);
    }
  }

  void removeListener(TrayListener listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _unwireTrayEvents();
    }
  }

  Future<void> destroy() async {
    _unwireTrayEvents();
    _menu = null;
    _menuBinding?.dispose();
    _menuBinding = null;
    _icon?.dispose();
    _icon = null;
    _trayIcon?.dispose();
    _trayIcon = null;
  }

  Future<void> setIcon(
    String iconPath, {
    bool isTemplate = false,
    TrayIconPosition iconPosition = TrayIconPosition.left,
    int iconSize = 18,
  }) async {
    final icon = iconPath.startsWith('data:image/')
        ? nativeapi.Image.fromBase64(iconPath)
        : nativeapi.ImageAsset.fromAsset(iconPath) ??
              nativeapi.Image.fromFile(iconPath);
    if (icon == null) {
      throw ArgumentError.value(
        iconPath,
        'iconPath',
        'Unable to load tray icon',
      );
    }

    // macOS only, as before; the other platforms record the values.
    _ensureTrayIcon
      ..isIconTemplate = isTemplate
      ..iconSize = Size.square(iconSize.toDouble())
      ..iconPosition = _nativePosition(iconPosition)
      ..icon = icon
      ..setVisible(true);
    _icon?.dispose();
    _icon = icon;
  }

  /// Sets the icon position of the tray icon.
  ///
  /// @platforms macos
  Future<void> setIconPosition(TrayIconPosition trayIconPosition) async {
    _ensureTrayIcon.iconPosition = _nativePosition(trayIconPosition);
  }

  Future<void> setToolTip(String toolTip) async {
    _ensureTrayIcon.setTooltip(toolTip);
  }

  Future<void> setTitle(String title) async {
    _ensureTrayIcon.setTitle(title);
  }

  Future<void> setContextMenu(Menu menu) async {
    final binding = NativeMenuBinding(menu, onItemClicked: _onMenuItemClicked);
    _ensureTrayIcon.setContextMenu(binding.menu);
    _menuBinding?.dispose();
    _menuBinding = binding;
    _menu = menu;
  }

  Future<void> popUpContextMenu({
    @Deprecated(
      'This parameter is only supported by the old platform implementation.',
    )
    bool bringAppToFront = false,
  }) async {
    _ensureTrayIcon.openContextMenu();
  }

  Future<Rect?> getBounds() async {
    return _ensureTrayIcon.getBounds();
  }

  nativeapi.TrayIcon? get trayIcon => _trayIcon;

  Menu? get contextMenu => _menu;

  nativeapi.TrayIconPosition _nativePosition(TrayIconPosition position) {
    return switch (position) {
      TrayIconPosition.left => nativeapi.TrayIconPosition.left,
      TrayIconPosition.right => nativeapi.TrayIconPosition.right,
    };
  }

  void _wireTrayEvents(nativeapi.TrayIcon trayIcon) {
    if (_listeners.isEmpty || _trayListenerId != null) {
      return;
    }

    // nativeapi reports whole clicks, so a click is replayed as down + up.
    _trayListenerId = trayIcon.addListener((event) {
      for (final listener in List<TrayListener>.of(_listeners)) {
        switch (event) {
          case nativeapi.TrayIconClickedEvent():
            listener.onTrayIconMouseDown();
            listener.onTrayIconMouseUp();
          case nativeapi.TrayIconRightClickedEvent():
            listener.onTrayIconRightMouseDown();
            listener.onTrayIconRightMouseUp();
          case nativeapi.TrayIconDoubleClickedEvent():
            break;
        }
      }
    });
  }

  void _unwireTrayEvents() {
    final listenerId = _trayListenerId;
    if (listenerId != null) {
      _trayIcon?.removeListener(listenerId);
    }
    _trayListenerId = null;
  }

  void _onMenuItemClicked(MenuItem menuItem) {
    menuItem.onClick?.call(menuItem);
    for (final listener in List<TrayListener>.of(_listeners)) {
      listener.onTrayMenuItemClick(menuItem);
    }
  }
}

final trayManager = TrayManager.instance;
