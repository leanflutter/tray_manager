import 'package:flutter/material.dart' hide Image;
import 'package:tray_manager/legacy.dart';
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

class _TrayExamplePageState extends State<TrayExamplePage> with TrayListener {
  TrayIcon? _trayIcon;
  Image? _icon;
  Menu? _menu;
  int? _clickListenerId;
  int? _rightClickListenerId;
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
      LegacyTrayManager.instance.removeListener(this);
    }
    LegacyTrayManager.instance.destroy();
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
  void onTrayMenuItemClick(MenuItem menuItem) {
    _log('Legacy TrayListener menu item: ${menuItem.label}');
  }

  void _createNativeTrayIcon([String iconPath = _defaultIconPath]) {
    _removeNativeListeners();
    _trayIcon?.dispose();
    _icon?.dispose();

    final icon = Image.fromAsset(iconPath);
    if (icon == null) {
      _log('Unable to create tray icon image.');
      return;
    }

    final trayIcon = TrayIcon()
      ..icon = icon
      ..title = 'tray_manager'
      ..tooltip = 'tray_manager nativeapi example'
      ..contextMenu = _buildMenu()
      ..contextMenuTrigger = ContextMenuTrigger.rightClicked
      ..isVisible = true;

    _clickListenerId = trayIcon.on<TrayIconClickedEvent>((event) {
      _log('Native tray icon clicked.');
    });
    _rightClickListenerId = trayIcon.on<TrayIconRightClickedEvent>((event) {
      _log('Native tray icon right clicked.');
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

    final icon = Image.fromAsset(iconPath);
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
    final menu = LegacyMenu();
    menu.addItem(MenuItem('Legacy menu item'));
    menu.addSeparator();
    menu.addItem(MenuItem('Close legacy menu'));

    if (!_legacyListenerAttached) {
      LegacyTrayManager.instance.addListener(this);
      _legacyListenerAttached = true;
    }

    await LegacyTrayManager.instance.setIcon(_iconPath);
    await LegacyTrayManager.instance.setTitle('tray_manager');
    await LegacyTrayManager.instance.setToolTip('LegacyTrayManager example');
    await LegacyTrayManager.instance.setContextMenu(menu);

    _log('LegacyTrayManager created a tray icon.');
  }

  Future<void> _showLegacyContextMenu() async {
    await LegacyTrayManager.instance.popUpContextMenu();
    _log('Requested legacy context menu.');
  }

  Menu _buildMenu() {
    final menu = Menu();

    final openItem = MenuItem('Open context menu');
    openItem.on<MenuItemClickedEvent>((event) {
      _trayIcon?.openContextMenu();
      _log('Menu item requested context menu.');
    });

    final checkedItem = MenuItem('Toggle checked state', MenuItemType.checkbox)
      ..state = MenuItemState.unchecked;
    checkedItem.on<MenuItemClickedEvent>((event) {
      checkedItem.state = checkedItem.state == MenuItemState.checked
          ? MenuItemState.unchecked
          : MenuItemState.checked;
      _log('Checkbox is ${checkedItem.state.name}.');
    });

    final destroyItem = MenuItem('Destroy tray icon');
    destroyItem.on<MenuItemClickedEvent>((event) {
      _destroyNativeTrayIcon();
    });

    menu
      ..addItem(openItem)
      ..addItem(checkedItem)
      ..addSeparator()
      ..addItem(destroyItem);

    _menu = menu;
    return menu;
  }

  void _removeNativeListeners() {
    final trayIcon = _trayIcon;
    if (trayIcon == null) {
      _clickListenerId = null;
      _rightClickListenerId = null;
      return;
    }

    final clickListenerId = _clickListenerId;
    if (clickListenerId != null) {
      trayIcon.off(clickListenerId);
    }

    final rightClickListenerId = _rightClickListenerId;
    if (rightClickListenerId != null) {
      trayIcon.off(rightClickListenerId);
    }

    _clickListenerId = null;
    _rightClickListenerId = null;
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
            child: const Text('Create LegacyTrayManager icon'),
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
