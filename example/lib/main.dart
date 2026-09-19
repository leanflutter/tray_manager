import 'package:flutter/material.dart' hide Image;
import 'package:tray_manager/legacy.dart' as legacy;
import 'package:tray_manager/tray_manager.dart';

const _defaultIconPath = 'images/tray_icon.png';
const _originalIconPath = 'images/tray_icon_original.png';

void main() {
  runApp(const TrayManagerExampleApp());
}

class TrayManagerExampleApp extends StatelessWidget {
  const TrayManagerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'tray_manager example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)),
      ),
      home: const TrayExamplePage(),
    );
  }
}

class TrayExamplePage extends StatefulWidget {
  const TrayExamplePage({super.key});

  @override
  State<TrayExamplePage> createState() => _TrayExamplePageState();
}

class _TrayExamplePageState extends State<TrayExamplePage>
    with legacy.TrayListener {
  TrayIcon? _trayIcon;
  Image? _icon;
  Menu? _menu;
  ListenerId? _trayListenerId;
  // Keeps the menu item wrappers (and their listeners) alive with the menu.
  final List<MenuItem> _menuItems = <MenuItem>[];
  int _eventCount = 0;
  String _status = 'Tray icon is not created.';
  String _iconPath = _defaultIconPath;
  bool _legacyListenerAttached = false;

  @override
  void dispose() {
    _removeNativeListeners();
    _trayIcon?.dispose();
    _icon?.dispose();
    if (_legacyListenerAttached) {
      legacy.trayManager.removeListener(this);
    }
    legacy.trayManager.destroy();
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    _log('Legacy TrayListener received tray mouse down.');
  }

  @override
  void onTrayIconRightMouseDown() {
    _log('Legacy TrayListener received tray right mouse down.');
  }

  @override
  void onTrayMenuItemClick(legacy.MenuItem menuItem) {
    _log('Legacy TrayListener menu item: ${menuItem.key}');
  }

  void _createNativeTrayIcon([String iconPath = _defaultIconPath]) {
    _removeNativeListeners();
    _trayIcon?.dispose();
    _icon?.dispose();

    final icon = ImageAsset.fromAsset(iconPath);
    if (icon == null) {
      _log('Unable to create tray icon image.');
      return;
    }

    final trayIcon = TrayIcon.create();
    if (trayIcon == null) {
      icon.dispose();
      _log('Unable to create tray icon.');
      return;
    }

    trayIcon
      ..icon = icon
      ..setTitle('tray_manager')
      ..setTooltip('tray_manager nativeapi example')
      ..setContextMenu(_buildMenu())
      ..setContextMenuTrigger(ContextMenuTrigger.rightClicked)
      ..setVisible(true);

    _trayListenerId = trayIcon.addListener((event) {
      switch (event) {
        case TrayIconClickedEvent():
          _log('Native tray icon clicked.');
        case TrayIconRightClickedEvent():
          _log('Native tray icon right clicked.');
        case TrayIconDoubleClickedEvent():
          _log('Native tray icon double clicked.');
      }
    });

    setState(() {
      _icon = icon;
      _iconPath = iconPath;
      _trayIcon = trayIcon;
      _status = 'Native tray icon is visible: $iconPath';
    });
  }

  void _setNativeTrayIcon(String iconPath) {
    final trayIcon = _trayIcon;
    if (trayIcon == null) {
      _createNativeTrayIcon(iconPath);
      return;
    }

    final icon = ImageAsset.fromAsset(iconPath);
    if (icon == null) {
      _log('Unable to create tray icon image.');
      return;
    }

    _icon?.dispose();
    trayIcon.icon = icon;
    setState(() {
      _icon = icon;
      _iconPath = iconPath;
      _status = 'Native tray icon changed: $iconPath';
    });
  }

  void _destroyNativeTrayIcon() {
    _removeNativeListeners();
    _trayIcon?.dispose();
    _icon?.dispose();
    setState(() {
      _trayIcon = null;
      _icon = null;
      _menu = null;
      _status = 'Native tray icon is destroyed.';
    });
  }

  Future<void> _createLegacyTrayIcon() async {
    final menu = legacy.Menu(
      items: [
        legacy.MenuItem(key: 'legacy_item', label: 'Legacy menu item'),
        legacy.MenuItem.checkbox(
          key: 'legacy_checkbox',
          label: 'Legacy checkbox',
          checked: false,
          onClick: (menuItem) {
            menuItem.checked = !(menuItem.checked == true);
          },
        ),
        legacy.MenuItem.separator(),
        legacy.MenuItem.submenu(
          key: 'legacy_submenu',
          label: 'Legacy submenu',
          submenu: legacy.Menu(
            items: [
              legacy.MenuItem(key: 'legacy_nested', label: 'Nested item'),
            ],
          ),
        ),
      ],
    );

    if (!_legacyListenerAttached) {
      legacy.trayManager.addListener(this);
      _legacyListenerAttached = true;
    }

    await legacy.trayManager.setIcon(_iconPath);
    await legacy.trayManager.setTitle('tray_manager');
    await legacy.trayManager.setToolTip('legacy TrayManager example');
    await legacy.trayManager.setContextMenu(menu);

    _log('legacy TrayManager created a tray icon.');
  }

  Future<void> _showLegacyContextMenu() async {
    await legacy.trayManager.popUpContextMenu();
    _log('Requested legacy context menu.');
  }

  Menu _buildMenu() {
    final menu = Menu.create()!;
    _menuItems.clear();

    final openItem = _menuItem('Open context menu', () {
      _trayIcon?.openContextMenu();
      _log('Menu item requested context menu.');
    });

    late final MenuItem checkedItem;
    checkedItem = _menuItem('Toggle checked state', () {
      checkedItem.state = checkedItem.state == MenuItemState.checked
          ? MenuItemState.unchecked
          : MenuItemState.checked;
      _log('Checkbox is ${checkedItem.state.name}.');
    }, type: MenuItemType.checkbox)..state = MenuItemState.unchecked;

    final destroyItem = _menuItem('Destroy tray icon', _destroyNativeTrayIcon);

    menu
      ..addItem(openItem)
      ..addItem(checkedItem)
      ..addSeparator()
      ..addItem(destroyItem);

    _menu = menu;
    return menu;
  }

  MenuItem _menuItem(
    String label,
    void Function() onClicked, {
    MenuItemType type = MenuItemType.normal,
  }) {
    final item = MenuItem.createWithLabelAndType(label, type)!;
    item.addListener((event) {
      if (event is MenuItemClickedEvent) onClicked();
    });
    _menuItems.add(item);
    return item;
  }

  void _removeNativeListeners() {
    final listenerId = _trayListenerId;
    if (listenerId != null) {
      _trayIcon?.removeListener(listenerId);
    }
    _trayListenerId = null;
  }

  void _log(String message) {
    setState(() {
      _eventCount += 1;
      _status = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuReady = _menu != null;
    return Scaffold(
      appBar: AppBar(title: const Text('tray_manager example')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_status, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Events: $_eventCount'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _createNativeTrayIcon,
            child: const Text('Create nativeapi TrayIcon'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: _defaultIconPath,
                label: Text('Default PNG'),
              ),
              ButtonSegment(
                value: _originalIconPath,
                label: Text('Original PNG'),
              ),
            ],
            selected: {_iconPath},
            onSelectionChanged: (selection) {
              _setNativeTrayIcon(selection.single);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: menuReady ? _trayIcon?.openContextMenu : null,
            child: const Text('Open native context menu'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _trayIcon == null ? null : _destroyNativeTrayIcon,
            child: const Text('Destroy native tray icon'),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: _createLegacyTrayIcon,
            child: const Text('Create legacy TrayManager icon'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _showLegacyContextMenu,
            child: const Text('Open legacy context menu'),
          ),
        ],
      ),
    );
  }
}
