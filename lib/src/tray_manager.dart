// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher, Rect, Size;

import 'package:nativeapi/nativeapi.dart' as nativeapi;
import 'package:tray_manager/src/menu.dart';
import 'package:tray_manager/src/tray_listener.dart';

// The channel method names of the 0.5.x implementation; part of its public API.
const kEventOnTrayIconMouseDown = 'onTrayIconMouseDown';
const kEventOnTrayIconMouseUp = 'onTrayIconMouseUp';
const kEventOnTrayIconRightMouseDown = 'onTrayIconRightMouseDown';
const kEventOnTrayIconRightMouseUp = 'onTrayIconRightMouseUp';
const kEventOnTrayMenuItemClick = 'onTrayMenuItemClick';

@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
enum TrayIconPosition { left, right }

/// The pre-nativeapi `TrayManager` on top of a single [nativeapi.TrayIcon],
/// for code that has not moved to the native API yet.
@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
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
    _disposeLater(_menuBinding);
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
              nativeapi.Image.fromFile(iconPath) ??
              _fromLinuxIconName(iconPath);
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
    _disposeLater(_menuBinding);
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

  /// The bounds of this tray icon, in logical pixels as before; null where the
  /// system does not tell (Linux).
  Future<Rect?> getBounds() async {
    final bounds = _ensureTrayIcon.getBounds();
    if (bounds.isEmpty) {
      return null;
    }
    if (!Platform.isWindows) {
      return bounds;
    }
    // Windows reports physical pixels; 0.5.x divided them by the view's ratio.
    final views = PlatformDispatcher.instance.views;
    final ratio = views.isEmpty ? 1.0 : views.first.devicePixelRatio;
    return Rect.fromLTWH(
      bounds.left / ratio,
      bounds.top / ratio,
      bounds.width / ratio,
      bounds.height / ratio,
    );
  }

  nativeapi.TrayIcon? get trayIcon => _trayIcon;

  Menu? get contextMenu => _menu;

  // In a Flatpak or Snap, 0.5.x took the *name* of an icon the package installs
  // (`org.example.app`) instead of a path, and let the panel look it up. The
  // icon now travels as pixels, so the lookup happens here.
  nativeapi.Image? _fromLinuxIconName(String name) {
    if (!Platform.isLinux || name.contains('/')) {
      return null;
    }
    final env = Platform.environment;
    final snap = env['SNAP'];
    final dataDirs = <String>[
      ...?env['XDG_DATA_DIRS']?.split(':'),
      '/app/share',
      if (snap != null) ...['$snap/usr/share', '$snap/share'],
      '/usr/local/share',
      '/usr/share',
    ];
    const sizes = ['48x48', '64x64', '32x32', '128x128', '256x256', '24x24'];
    final candidates = <String>[
      if (snap != null) '$snap/meta/gui/$name.png',
      for (final dir in dataDirs) ...[
        for (final size in sizes) '$dir/icons/hicolor/$size/apps/$name.png',
        '$dir/icons/hicolor/scalable/apps/$name.svg',
        '$dir/pixmaps/$name.png',
      ],
    ];
    for (final candidate in candidates) {
      if (candidate.startsWith('/') && File(candidate).existsSync()) {
        final image = nativeapi.Image.fromFile(candidate);
        if (image != null) {
          return image;
        }
      }
    }
    return null;
  }

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

  // 0.5.x apps call setContextMenu (or destroy) from onTrayMenuItemClick, which
  // runs inside the clicked item's own native callback; the item has to
  // outlive that call.
  void _disposeLater(NativeMenuBinding? binding) {
    if (binding != null) {
      Timer.run(binding.dispose);
    }
  }

  void _onMenuItemClicked(MenuItem menuItem) {
    menuItem.onClick?.call(menuItem);
    for (final listener in List<TrayListener>.of(_listeners)) {
      listener.onTrayMenuItemClick(menuItem);
    }
  }
}

@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
final trayManager = TrayManager.instance;
