// Guards the promise of package:tray_manager/legacy.dart: code written for
// tray_manager 0.5.x compiles unchanged. `_surface` names every public symbol
// of 0.5.3 (and of menu_base 0.1.1, which it re-exported) with its old
// signature; it is compiled, never run, because running needs the native
// library. The tests below cover the parts that are plain Dart.
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/legacy.dart';

class _Mixed with TrayListener {}

class _Extended extends TrayListener {}

class _Implemented implements TrayListener {
  @override
  void onTrayIconMouseDown() {}
  @override
  void onTrayIconMouseUp() {}
  @override
  void onTrayIconRightMouseDown() {}
  @override
  void onTrayIconRightMouseUp() {}
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {}
}

class _Behavior implements MenuBehavior {
  @override
  Future<void> popUp(
    Menu menu, {
    Offset? position,
    Placement placement = Placement.topLeft,
  }) async {}
}

Future<void> _surface() async {
  final TrayManager manager = TrayManager.instance;
  final bool hasListeners = trayManager.hasListeners;
  trayManager.addListener(_Mixed());
  trayManager.removeListener(_Extended());
  await trayManager.destroy();
  await trayManager.setIcon('a.png');
  await trayManager.setIcon(
    'a.png',
    isTemplate: true,
    iconPosition: TrayIconPosition.right,
    iconSize: 20,
  );
  await trayManager.setIconPosition(TrayIconPosition.left);
  await trayManager.setToolTip('t');
  await trayManager.setTitle('t');
  await trayManager.popUpContextMenu();
  await trayManager.popUpContextMenu(bringAppToFront: true);
  final Rect? bounds = await trayManager.getBounds();
  await trayManager.setContextMenu(Menu(items: [MenuItem.separator()]));
}

void main() {
  test('channel method names are still exported', () {
    expect(
      [
        kEventOnTrayIconMouseDown,
        kEventOnTrayIconMouseUp,
        kEventOnTrayIconRightMouseDown,
        kEventOnTrayIconRightMouseUp,
        kEventOnTrayMenuItemClick,
      ],
      [
        'onTrayIconMouseDown',
        'onTrayIconMouseUp',
        'onTrayIconRightMouseDown',
        'onTrayIconRightMouseUp',
        'onTrayMenuItemClick',
      ],
    );
    expect(Placement.values, hasLength(4));
  });

  test('MenuItem keeps the menu_base constructors, fields and json', () {
    final item = MenuItem(
      key: 'k',
      type: 'normal',
      label: 'l',
      sublabel: 's',
      toolTip: 't',
      icon: 'i.png',
      checked: false,
      disabled: false,
      submenu: Menu(items: []),
      onClick: (MenuItem menuItem) {},
      onHighlight: (MenuItem menuItem) {},
      onLoseHighlight: (MenuItem menuItem) {},
    );
    expect(item.toJson(), {
      'id': item.id,
      'key': 'k',
      'type': 'normal',
      'label': 'l',
      'toolTip': 't',
      'icon': 'i.png',
      'checked': false,
      'disabled': false,
      'submenu': {'items': <dynamic>[]},
    });

    final separator = MenuItem.separator();
    expect(separator.type, 'separator');
    expect(separator.disabled, isTrue);
    expect(separator.toJson(), {
      'id': separator.id,
      'type': 'separator',
      'label': '',
      'disabled': true,
    });

    final submenu = MenuItem.submenu(key: 's', label: 'l', submenu: Menu());
    expect(submenu.type, 'submenu');
    final checkbox = MenuItem.checkbox(key: 'c', label: 'l', checked: null);
    expect(checkbox.type, 'checkbox');
    expect(checkbox.checked, isNull);

    // Every field was assignable, before and after setContextMenu.
    item
      ..id = 5
      ..key = 'x'
      ..type = 'checkbox'
      ..label = null
      ..sublabel = null
      ..toolTip = null
      ..icon = null
      ..checked = true
      ..disabled = true
      ..submenu = null
      ..onClick = null
      ..onHighlight = null
      ..onLoseHighlight = null;
    expect(item.id, 5);
    expect(item.checked, isTrue);
    expect(item.disabled, isTrue);
  });

  test('ids count up from 1024 like menu_base', () {
    final first = MenuItem(label: 'a');
    final second = MenuItem(label: 'b');
    expect(first.id, greaterThanOrEqualTo(1024));
    expect(second.id, first.id + 1);
  });

  test('Menu finds items by key and id through submenus', () {
    final nested = MenuItem(key: 'nested', label: 'n');
    final menu = Menu(
      items: [
        MenuItem(key: 'a', label: 'a'),
        MenuItem.submenu(
          key: 'sub',
          submenu: Menu(items: [nested]),
        ),
      ],
    );
    expect(menu.getMenuItem('nested'), same(nested));
    expect(menu.getMenuItemById(nested.id), same(nested));
    expect(menu.getMenuItem('missing'), isNull);
    expect(Menu().getMenuItem('a'), isNull);
    expect(Menu().toJson(), <String, dynamic>{});
    menu.items = [nested];
    menu.items?.add(MenuItem.separator());
    expect(menu.items, hasLength(2));
  });

  test('listeners are tracked without touching the tray', () {
    final listener = _Implemented();
    expect(trayManager.hasListeners, isFalse);
    trayManager.addListener(listener);
    expect(trayManager.hasListeners, isTrue);
    trayManager.removeListener(listener);
    expect(trayManager.hasListeners, isFalse);
  });
}
