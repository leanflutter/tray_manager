import 'dart:async';

import 'package:nativeapi/nativeapi.dart' as nativeapi;
import 'package:tray_manager/src/tray_listener.dart';

enum TrayIconPosition { left, right }

class LegacyMenu extends nativeapi.Menu {
  LegacyMenu();

  final List<nativeapi.MenuItem> _items = <nativeapi.MenuItem>[];

  List<nativeapi.MenuItem> get items =>
      List<nativeapi.MenuItem>.unmodifiable(_items);

  @override
  void addItem(nativeapi.MenuItem item) {
    _items.add(item);
    super.addItem(item);
  }

  @override
  void insertItem(int index, nativeapi.MenuItem item) {
    _items.insert(index, item);
    super.insertItem(index, item);
  }

  @override
  bool removeItem(nativeapi.MenuItem item) {
    final removed = super.removeItem(item);
    if (removed) {
      _items.remove(item);
    }
    return removed;
  }

  @override
  bool removeItemById(int itemId) {
    final removed = super.removeItemById(itemId);
    if (removed) {
      _items.removeWhere((item) => item.id == itemId);
    }
    return removed;
  }

  @override
  bool removeItemAt(int index) {
    final removed = super.removeItemAt(index);
    if (removed) {
      _items.removeAt(index);
    }
    return removed;
  }
}

class LegacyTrayManager {
  LegacyTrayManager._();

  static final LegacyTrayManager instance = LegacyTrayManager._();

  nativeapi.TrayIcon? _trayIcon;
  nativeapi.Image? _icon;
  nativeapi.Menu? _menu;
  final List<TrayListener> _listeners = <TrayListener>[];
  final List<int> _trayEventListenerIds = <int>[];
  final Map<nativeapi.MenuItem, int> _menuItemListenerIds =
      <nativeapi.MenuItem, int>{};

  nativeapi.TrayIcon get _ensureTrayIcon {
    final trayIcon = _trayIcon ??= nativeapi.TrayIcon()..isVisible = true;
    _wireTrayEvents(trayIcon);
    return trayIcon;
  }

  bool get isSupported => nativeapi.TrayManager.instance.isSupported;

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
    final menu = _menu;
    if (menu != null) {
      _wireMenuEvents(menu);
    }
  }

  void removeListener(TrayListener listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _unwireTrayEvents();
      _unwireMenuEvents();
    }
  }

  Future<void> destroy() async {
    _unwireTrayEvents();
    _unwireMenuEvents();
    _menu = null;
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
        : nativeapi.Image.fromAsset(iconPath) ??
              nativeapi.Image.fromFile(iconPath);
    if (icon == null) {
      throw ArgumentError.value(
        iconPath,
        'iconPath',
        'Unable to load tray icon',
      );
    }

    _icon?.dispose();
    _icon = icon;
    _ensureTrayIcon
      ..icon = icon
      ..isVisible = true;
  }

  Future<void> setIconPosition(TrayIconPosition trayIconPosition) async {
    // nativeapi does not currently expose tray icon positioning.
  }

  Future<void> setToolTip(String toolTip) async {
    _ensureTrayIcon.tooltip = toolTip;
  }

  Future<void> setTitle(String title) async {
    _ensureTrayIcon.title = title;
  }

  Future<void> setContextMenu(nativeapi.Menu menu) async {
    _unwireMenuEvents();
    _menu = menu;
    _ensureTrayIcon.contextMenu = menu;
    _wireMenuEvents(menu);
  }

  Future<void> popUpContextMenu({
    @Deprecated(
      'This parameter is only supported by the old platform implementation.',
    )
    bool bringAppToFront = false,
  }) async {
    _ensureTrayIcon.openContextMenu();
  }

  Future<nativeapi.Rect?> getBounds() async {
    return _ensureTrayIcon.bounds;
  }

  nativeapi.TrayIcon? get trayIcon => _trayIcon;

  nativeapi.Menu? get contextMenu => _menu;

  void _wireTrayEvents(nativeapi.TrayIcon trayIcon) {
    if (_listeners.isEmpty || _trayEventListenerIds.isNotEmpty) {
      return;
    }

    _trayEventListenerIds.addAll([
      trayIcon.on<nativeapi.TrayIconClickedEvent>((event) {
        for (final listener in List<TrayListener>.of(_listeners)) {
          listener.onTrayIconMouseDown();
          listener.onTrayIconMouseUp();
        }
      }),
      trayIcon.on<nativeapi.TrayIconRightClickedEvent>((event) {
        for (final listener in List<TrayListener>.of(_listeners)) {
          listener.onTrayIconRightMouseDown();
          listener.onTrayIconRightMouseUp();
        }
      }),
    ]);
  }

  void _unwireTrayEvents() {
    final trayIcon = _trayIcon;
    if (trayIcon == null) {
      _trayEventListenerIds.clear();
      return;
    }
    for (final listenerId in _trayEventListenerIds) {
      trayIcon.off(listenerId);
    }
    _trayEventListenerIds.clear();
  }

  void _wireMenuEvents(nativeapi.Menu menu) {
    if (_listeners.isEmpty || menu is! LegacyMenu) {
      return;
    }

    for (final item in menu.items) {
      _wireMenuItemEvent(item);
      final submenu = item.submenu;
      if (submenu != null) {
        _wireMenuEvents(submenu);
      }
    }
  }

  void _wireMenuItemEvent(nativeapi.MenuItem item) {
    if (_menuItemListenerIds.containsKey(item)) {
      return;
    }

    _menuItemListenerIds[item] = item.on<nativeapi.MenuItemClickedEvent>((
      event,
    ) {
      for (final listener in List<TrayListener>.of(_listeners)) {
        listener.onTrayMenuItemClick(item);
      }
    });
  }

  void _unwireMenuEvents() {
    for (final entry in _menuItemListenerIds.entries) {
      entry.key.off(entry.value);
    }
    _menuItemListenerIds.clear();
  }
}
