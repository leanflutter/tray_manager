// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:math' as math;

import 'package:nativeapi/nativeapi.dart' as nativeapi;

// Same id range the old platform implementations relied on; kept so that ids
// stored by existing apps keep their shape.
const int _maxMenuItemId = 65535;
const int _minMenuItemId = 1024;
int _nextMenuItemId = _minMenuItemId;

int _generateMenuItemId() {
  final newId = _nextMenuItemId;
  _nextMenuItemId = math.max(
    _minMenuItemId,
    (_nextMenuItemId + 1) % _maxMenuItemId,
  );
  return newId;
}

/// The declarative menu the old `tray_manager` API took.
///
/// It is a plain description; `TrayManager.setContextMenu` turns it into a
/// [nativeapi.Menu]. Changing [items] afterwards needs another
/// `setContextMenu` call, as it always did.
@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
class Menu {
  Menu({this.items});

  List<MenuItem>? items;

  MenuItem? getMenuItem(String key) {
    for (final menuItem in items ?? const <MenuItem>[]) {
      if (menuItem.key == key) {
        return menuItem;
      }
      final nested = menuItem.submenu?.getMenuItem(key);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  MenuItem? getMenuItemById(int id) {
    for (final menuItem in items ?? const <MenuItem>[]) {
      if (menuItem.id == id) {
        return menuItem;
      }
      final nested = menuItem.submenu?.getMenuItemById(id);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'items': items?.map((e) => e.toJson()).toList()}
      ..removeWhere((key, value) => value == null);
  }
}

/// One entry of a [Menu].
///
/// [label], [toolTip], [checked] and [disabled] are live: once the menu has
/// been handed to `setContextMenu`, assigning them updates the native item, so
/// `menuItem.checked = !menuItem.checked` inside [onClick] is enough.
@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
class MenuItem {
  MenuItem({
    this.key,
    this.type = 'normal',
    String? label,
    this.sublabel,
    String? toolTip,
    this.icon,
    bool? checked,
    bool disabled = false,
    this.submenu,
    this.onClick,
    this.onHighlight,
    this.onLoseHighlight,
  }) : id = _generateMenuItemId(),
       _label = label,
       _toolTip = toolTip,
       _checked = checked,
       _disabled = disabled;

  MenuItem.separator()
    : id = _generateMenuItemId(),
      type = 'separator',
      _disabled = true;

  MenuItem.submenu({
    this.key,
    String? label,
    this.sublabel,
    String? toolTip,
    this.icon,
    bool disabled = false,
    this.submenu,
    this.onClick,
    this.onHighlight,
    this.onLoseHighlight,
  }) : id = _generateMenuItemId(),
       type = 'submenu',
       _label = label,
       _toolTip = toolTip,
       _disabled = disabled;

  MenuItem.checkbox({
    this.key,
    String? label,
    this.sublabel,
    String? toolTip,
    this.icon,
    required bool? checked,
    bool disabled = false,
    this.onClick,
    this.onHighlight,
    this.onLoseHighlight,
  }) : id = _generateMenuItemId(),
       type = 'checkbox',
       _label = label,
       _toolTip = toolTip,
       _checked = checked,
       _disabled = disabled;

  int id;
  String? key;

  /// `normal`, `separator`, `submenu` or `checkbox`.
  String type;

  /// Not shown by the native menu; kept for source compatibility.
  String? sublabel;

  /// An asset name or a file path.
  String? icon;
  Menu? submenu;

  void Function(MenuItem menuItem)? onClick;

  /// Never called by the native menu; kept for source compatibility.
  void Function(MenuItem menuItem)? onHighlight;

  /// Never called by the native menu; kept for source compatibility.
  void Function(MenuItem menuItem)? onLoseHighlight;

  String? _label;
  String? _toolTip;
  bool? _checked;
  bool _disabled = false;
  nativeapi.MenuItem? _native;

  String? get label => _label;

  set label(String? value) {
    _label = value;
    _native?.label = value ?? '';
  }

  String? get toolTip => _toolTip;

  set toolTip(String? value) {
    _toolTip = value;
    _native?.tooltip = value;
  }

  bool? get checked => _checked;

  set checked(bool? value) {
    _checked = value;
    _native?.state = _nativeState;
  }

  bool get disabled => _disabled;

  set disabled(bool value) {
    _disabled = value;
    _native?.isEnabled = !value;
  }

  nativeapi.MenuItemState get _nativeState => _checked == true
      ? nativeapi.MenuItemState.checked
      : nativeapi.MenuItemState.unchecked;

  // The old implementations drew a check mark on any item that carried
  // `checked`, so a normal item with a value becomes a native checkbox.
  nativeapi.MenuItemType get _nativeType => switch (type) {
    'submenu' => nativeapi.MenuItemType.submenu,
    _ when submenu != null => nativeapi.MenuItemType.submenu,
    'checkbox' => nativeapi.MenuItemType.checkbox,
    _ =>
      _checked == null
          ? nativeapi.MenuItemType.normal
          : nativeapi.MenuItemType.checkbox,
  };

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'key': key,
      'type': type,
      'label': label ?? '',
      'toolTip': toolTip,
      'icon': icon,
      'checked': checked,
      'disabled': disabled,
      'submenu': submenu?.toJson(),
    }..removeWhere((key, value) => value == null);
  }
}

/// The native menu built from a [Menu], and everything that has to stay alive
/// with it: nativeapi wrappers free their handle when collected, and a
/// listener only lasts as long as the wrapper it was added to.
class NativeMenuBinding {
  NativeMenuBinding(Menu menu, {required this.onItemClicked}) {
    this.menu = _build(menu);
  }

  final void Function(MenuItem menuItem) onItemClicked;

  late final nativeapi.Menu menu;
  final List<nativeapi.Menu> _menus = <nativeapi.Menu>[];
  final List<nativeapi.Image> _icons = <nativeapi.Image>[];
  final Map<MenuItem, (nativeapi.MenuItem, nativeapi.ListenerId)> _items =
      <MenuItem, (nativeapi.MenuItem, nativeapi.ListenerId)>{};

  nativeapi.Menu _build(Menu menu) {
    final nativeMenu = nativeapi.Menu.create();
    if (nativeMenu == null) {
      throw StateError('Unable to create the context menu');
    }
    _menus.add(nativeMenu);

    for (final menuItem in menu.items ?? const <MenuItem>[]) {
      if (menuItem.type == 'separator') {
        nativeMenu.addSeparator();
        continue;
      }

      final nativeItem = nativeapi.MenuItem.createWithLabelAndType(
        menuItem.label ?? '',
        menuItem._nativeType,
      );
      if (nativeItem == null) {
        throw StateError('Unable to create the menu item ${menuItem.label}');
      }

      nativeItem.isEnabled = !menuItem.disabled;
      if (menuItem.toolTip != null) {
        nativeItem.tooltip = menuItem.toolTip;
      }
      if (menuItem._nativeType == nativeapi.MenuItemType.checkbox) {
        nativeItem.state = menuItem._nativeState;
      }
      final iconPath = menuItem.icon;
      if (iconPath != null) {
        final icon =
            nativeapi.ImageAsset.fromAsset(iconPath) ??
            nativeapi.Image.fromFile(iconPath);
        if (icon != null) {
          nativeItem.icon = icon;
          _icons.add(icon);
        }
      }
      final submenu = menuItem.submenu;
      if (submenu != null) {
        nativeItem.submenu = _build(submenu);
      }

      final listenerId = nativeItem.addListener((event) {
        if (event is! nativeapi.MenuItemClickedEvent) {
          return;
        }
        onItemClicked(menuItem);
        // 0.5.x menus showed exactly what `checked` said. Some platforms tick
        // a check item by themselves when it is clicked, so say it again.
        if (identical(menuItem._native, nativeItem) &&
            menuItem._nativeType == nativeapi.MenuItemType.checkbox) {
          nativeItem.state = menuItem._nativeState;
        }
      });
      _items[menuItem] = (nativeItem, listenerId);
      menuItem._native = nativeItem;
      nativeMenu.addItem(nativeItem);
    }
    return nativeMenu;
  }

  void dispose() {
    for (final MapEntry(key: menuItem, value: (nativeItem, listenerId))
        in _items.entries) {
      nativeItem.removeListener(listenerId);
      if (identical(menuItem._native, nativeItem)) {
        menuItem._native = null;
      }
      nativeItem.dispose();
    }
    _items.clear();
    for (final icon in _icons) {
      icon.dispose();
    }
    _icons.clear();
    for (final nativeMenu in _menus) {
      nativeMenu.dispose();
    }
    _menus.clear();
  }
}
