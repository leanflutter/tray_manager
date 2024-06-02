import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

const _kIconTypeDefault = 'default';
const _kIconTypeOriginal = 'original';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  String _iconType = _kIconTypeOriginal;
  Menu? _menu;

  Timer? _timer;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _handleSetIcon(String iconType) async {
    _iconType = iconType;
    String iconPath =
        Platform.isWindows ? 'images/tray_icon.ico' : 'images/tray_icon.png';

    if (_iconType == 'original') {
      iconPath = Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png';
    }

    await trayManager.setIcon(iconPath);
    // Follow Linux system icon theme
    // await trayManager.setIcon(iconPath, preferIconTheme: true, iconName: 'flutter');
  }

  void _startIconFlashing() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _handleSetIcon(
        _iconType == _kIconTypeOriginal
            ? _kIconTypeDefault
            : _kIconTypeOriginal,
      );
    });
    setState(() {});
  }

  void _stopIconFlashing() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          title: const Text('destroy'),
          onTap: () {
            trayManager.destroy();
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setIcon'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (_) {
                  bool isFlashing = (_timer != null && _timer!.isActive);
                  return TextButton(
                    onPressed:
                        isFlashing ? _stopIconFlashing : _startIconFlashing,
                    child: isFlashing
                        ? const Text('stop flash')
                        : const Text('start flash'),
                  );
                },
              ),
              TextButton(
                child: const Text('Default'),
                onPressed: () => _handleSetIcon(_kIconTypeDefault),
              ),
              TextButton(
                child: const Text('Original'),
                onPressed: () => _handleSetIcon(_kIconTypeOriginal),
              ),
            ],
          ),
          onTap: () => _handleSetIcon(_kIconTypeDefault),
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setIconPosition'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: const Text('left'),
                onPressed: () {
                  trayManager.setIconPosition(TrayIconPositon.left);
                },
              ),
              TextButton(
                child: const Text('right'),
                onPressed: () {
                  trayManager.setIconPosition(TrayIconPositon.right);
                },
              ),
            ],
          ),
          onTap: () => _handleSetIcon(_kIconTypeDefault),
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setToolTip'),
          onTap: () async {
            await trayManager.setToolTip('tray_manager');
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setTitle'),
          onTap: () async {
            await trayManager.setTitle('tray_manager');
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setContextMenu'),
          onTap: () async {
            _menu ??= Menu(
              items: [
                MenuItem(
                  label: 'Look Up "LeanFlutter"',
                ),
                MenuItem(
                  label: 'Search with Google',
                ),
                MenuItem.separator(),
                MenuItem(
                  label: 'Cut',
                ),
                MenuItem(
                  label: 'Copy',
                ),
                MenuItem(
                  label: 'Paste',
                  disabled: true,
                ),
                MenuItem.submenu(
                  label: 'Share',
                  submenu: Menu(
                    items: [
                      MenuItem.checkbox(
                        label: 'Item 1',
                        checked: true,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 1');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                      MenuItem.checkbox(
                        label: 'Item 2',
                        checked: false,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 2');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                    ],
                  ),
                ),
                MenuItem.separator(),
                MenuItem.submenu(
                  label: 'Font',
                  submenu: Menu(
                    items: [
                      MenuItem.checkbox(
                        label: 'Item 1',
                        checked: true,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 1');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                      MenuItem.checkbox(
                        label: 'Item 2',
                        checked: false,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 2');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                      MenuItem.separator(),
                      MenuItem(
                        label: 'Item 3',
                        checked: false,
                      ),
                      MenuItem(
                        label: 'Item 4',
                        checked: false,
                      ),
                      MenuItem(
                        label: 'Item 5',
                        checked: false,
                      ),
                    ],
                  ),
                ),
                MenuItem.submenu(
                  label: 'Speech',
                  submenu: Menu(
                    items: [
                      MenuItem(
                        label: 'Item 1',
                      ),
                      MenuItem(
                        label: 'Item 2',
                      ),
                    ],
                  ),
                ),
              ],
            );
            await trayManager.setContextMenu(_menu!);
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('popUpContextMenu'),
          onTap: () async {
            await trayManager.popUpContextMenu();
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('getBounds'),
          onTap: () async {
            Rect? bounds = await trayManager.getBounds();
            if (bounds != null) {
              Size size = bounds.size;
              Offset origin = bounds.topLeft;
              BotToast.showText(
                text: '${size.toString()}\n${origin.toString()}',
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: _buildBody(context),
    );
  }

  @override
  void onTrayIconMouseDown() {
    if (kDebugMode) {
      print('onTrayIconMouseDown');
    }
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseUp() {
    if (kDebugMode) {
      print('onTrayIconMouseUp');
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    if (kDebugMode) {
      print('onTrayIconRightMouseDown');
    }
    // trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    if (kDebugMode) {
      print('onTrayIconRightMouseUp');
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (kDebugMode) {
      print(menuItem.toJson());
    }
    BotToast.showText(
      text: '${menuItem.toJson()}',
    );
  }
}
