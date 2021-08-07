import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:preference_list/preference_list.dart';
import 'package:tray_manager/tray_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  @override
  void initState() {
    TrayManager.instance.addListener(this);
    super.initState();
  }
  
  @override
  void dispose() {
    TrayManager.instance.removeListener(this);
    super.dispose();
  }

  Widget _buildBody(BuildContext context) {
    return PreferenceList(
      children: <Widget>[
        PreferenceListSection(
          children: [
            PreferenceListItem(
              title: Text('getFrame'),
              onTap: () async {
                Rect frame = await TrayManager.instance.getFrame();
                Size size = frame.size;
                Offset origin = frame.topLeft;
                BotToast.showText(
                    text: '${size.toString()}\n${origin.toString()}');
              },
            ),
            PreferenceListItem(
              title: Text('setIcon'),
              onTap: () async {
                await TrayManager.instance.setIcon('images/tray_icon.png');
              },
            ),
            PreferenceListItem(
              title: Text('setToolTip'),
              onTap: () async {
                await TrayManager.instance.setToolTip('tray_manager');
              },
            ),
            PreferenceListItem(
              title: Text('setContextMenu'),
              onTap: () async {
                List<MenuItem> menuItems = [
                  MenuItem(title: 'Undo'),
                  MenuItem(title: 'Redo'),
                  MenuItem.separator,
                  MenuItem(title: 'Cut'),
                  MenuItem(title: 'Copy'),
                  MenuItem(title: 'Paste'),
                  MenuItem.separator,
                  MenuItem(title: 'Find'),
                  MenuItem(title: 'Replace'),
                ];
                await TrayManager.instance.setContextMenu(menuItems);
              },
            ),
            PreferenceListItem(
              title: Text('popUpContextMenu'),
              onTap: () async {
                await TrayManager.instance.popUpContextMenu();
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
  void onTrayIconMouseUp() {
    TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    print(TrayManager.instance.getFrame());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    print(menuItem.toJson());
  }
}
