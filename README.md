# tray_manager

[![pub version][pub-image]][pub-url]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager

This plugin allows Flutter **desktop** apps to defines system tray.

[![Discord](https://img.shields.io/badge/discord-%237289DA.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/zPa6EZ2jqb)

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [tray_manager](#tray_manager)
  - [Platform Support](#platform-support)
  - [Quick Start](#quick-start)
    - [Installation](#installation)
      - [⚠️ Linux requirements](#️-linux-requirements)
    - [Usage](#usage)
      - [Listening events](#listening-events)
  - [API](#api)
    - [TrayManager](#traymanager)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Platform Support

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|   ✔️   |   ✔️   |    ✔️    |

## Quick Start

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  tray_manager: ^0.1.2
```

Or

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: main
```

#### ⚠️ Linux requirements

- `appindicator3-0.1`

Run the following command

```
sudo apt-get install appindicator3-0.1 libappindicator3-dev
```

### Usage

Register/Unregsiter a system/inapp wide hot key.

```dart
import 'package:tray_manager/tray_manager.dart';

await TrayManager.instance.setIcon(
  Platform.isWindows
    ? 'images/tray_icon.ico'
    : 'images/tray_icon.png',
);
List<MenuItem> items = [
  MenuItem(
    key: 'show_window',
    title: 'Show Window',
  ),
  MenuItem.separator,
  MenuItem(
    key: 'exit_app',
    title: 'Exit App',
  ),
];
await TrayManager.instance.setContextMenu(items);
```

> Please see the example app of this plugin for a full example.

#### Listening events

```dart
import 'package:flutter/material.dart';
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
    _init();
  }

  @override
  void dispose() {
    TrayManager.instance.removeListener(this);
    super.dispose();
  }

  void _init() {
    // ...
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }

  @override
  void onTrayIconMouseDown() {
    // do something
  }

  @override
  void onTrayIconRightMouseDown() {
    // do something
  }

  @override
  void onTrayIconRightMouseUp() {
    // do something
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      // do something
    } else if (menuItem.key == 'exit_app') {
       // do something
    }
  }
}
```

## API

### TrayManager

| Method           | Description                                                                                                                     | Linux | macOS | Windows |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------- | ----- | ----- | ------- |
| destroy          | Destroys the tray icon immediately.                                                                                             | ✔️     | ✔️     | ✔️       |
| setIcon          | Sets the image associated with this tray icon.                                                                                  | ✔️     | ✔️     | ✔️       |
| setContextMenu   | -                                                                                                                               | ✔️     | ✔️     | ✔️       |
| popUpContextMenu | Pops up the context menu of the tray icon. When menu is passed, the menu will be shown instead of the tray icon's context menu. | ➖     | ✔️     | ✔️       |
| getBounds        | Returns `Rect` The bounds of this tray icon.                                                                                    | ✔️     | ✔️     | ✔️       |

## License

[MIT](./LICENSE)
