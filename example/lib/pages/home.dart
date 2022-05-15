import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart' hide MenuItem;
import 'package:flutter/material.dart' hide MenuItem;
import 'package:preference_list/preference_list.dart';
import 'package:tray_manager/tray_manager.dart';

const _kIconTypeDefault = 'default';
const _kIconTypeOriginal = 'original';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
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

  void _handleSetIcon(String iconType) async {
    _iconType = iconType;
    String iconPath =
        Platform.isWindows ? 'images/tray_icon.ico' : 'images/tray_icon.png';

    if (_iconType == 'original') {
      iconPath = Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png';
    }

    await trayManager.setIcon(iconPath);
  }

  void _startIconFlashing() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      _handleSetIcon(_iconType == _kIconTypeOriginal
          ? _kIconTypeDefault
          : _kIconTypeOriginal);
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
    return PreferenceList(
      children: <Widget>[
        PreferenceListSection(
          children: [
            PreferenceListItem(
              title: Text('destroy'),
              onTap: () {
                trayManager.destroy();
              },
            ),
            PreferenceListItem(
              title: Text('setIcon'),
              accessoryView: Row(
                children: [
                  Builder(builder: (_) {
                    bool isFlashing = (_timer != null && _timer!.isActive);
                    return CupertinoButton(
                      child:
                          isFlashing ? Text('stop flash') : Text('start flash'),
                      onPressed:
                          isFlashing ? _stopIconFlashing : _startIconFlashing,
                    );
                  }),
                  CupertinoButton(
                    child: Text('Default'),
                    onPressed: () => _handleSetIcon(_kIconTypeDefault),
                  ),
                  CupertinoButton(
                    child: Text('Original'),
                    onPressed: () => _handleSetIcon(_kIconTypeOriginal),
                  ),
                ],
              ),
              onTap: () => _handleSetIcon(_kIconTypeDefault),
            ),
            PreferenceListItem(
              title: Text('setToolTip'),
              onTap: () async {
                await trayManager.setToolTip('tray_manager');
              },
            ),
            PreferenceListItem(
              title: Text('setTitle'),
              onTap: () async {
                await trayManager.setTitle('tray_manager');
              },
            ),
            PreferenceListItem(
              title: Text('setContextMenu'),
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
                              print('click item 1');
                              menuItem.checked = !(menuItem.checked == true);
                            },
                          ),
                          MenuItem.checkbox(
                            label: 'Item 2',
                            checked: false,
                            onClick: (menuItem) {
                              print('click item 2');
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
                              print('click item 1');
                              menuItem.checked = !(menuItem.checked == true);
                            },
                          ),
                          MenuItem.checkbox(
                            label: 'Item 2',
                            checked: false,
                            onClick: (menuItem) {
                              print('click item 2');
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
            PreferenceListItem(
              title: Text('popUpContextMenu'),
              onTap: () async {
                await trayManager.popUpContextMenu();
              },
            ),
            PreferenceListItem(
              title: Text('getBounds'),
              onTap: () async {
                Rect bounds = await trayManager.getBounds();
                Size size = bounds.size;
                Offset origin = bounds.topLeft;
                BotToast.showText(
                  text: '${size.toString()}\n${origin.toString()}',
                );
              },
            ),
          ],
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
    print('onTrayIconMouseDown');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseUp() {
    print('onTrayIconMouseUp');
  }

  @override
  void onTrayIconRightMouseDown() {
    print('onTrayIconRightMouseDown');
    // trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    print('onTrayIconRightMouseUp');
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    print(menuItem.toJson());
    BotToast.showText(
      text: '${menuItem.toJson()}',
    );
  }
}
