# tray_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url] ![][visits-count-image]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb
[visits-count-image]: https://img.shields.io/badge/dynamic/json?label=Visits%20Count&query=value&url=https://api.countapi.xyz/hit/leanflutter.tray_manager/visits

This plugin allows Flutter desktop apps to defines system tray.

---

English | [简体中文](./README-ZH.md)

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Platform Support](#platform-support)
- [Screenshots](#screenshots)
- [Known Issues](#known-issues)
  - [Not Working with app_links](#not-working-with-app_links)
- [Quick Start](#quick-start)
  - [Installation](#installation)
    - [Linux requirements](#linux-requirements)
  - [Usage](#usage)
    - [Listening events](#listening-events)
- [Who's using it?](#whos-using-it)
- [API](#api)
  - [TrayManager](#traymanager)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Platform Support

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|  ✔️   |  ✔️   |   ✔️    |

## Screenshots

| macOS                                                                                     | Linux                                                                                     | Windows                                                                                          |
| ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| ![](https://github.com/leanflutter/tray_manager/blob/main/screenshots/macos.png?raw=true) | ![](https://github.com/leanflutter/tray_manager/blob/main/screenshots/linux.png?raw=true) | ![image](https://github.com/leanflutter/tray_manager/blob/main/screenshots/windows.png?raw=true) |

## Known Issues

### Not Working with app_links

When using `app_links` package alongside `tray_manager`, you may find that plugin does not work properly. This is because `app_links` internally blocks event propagation, preventing menu click events from being triggered.

To resolve this issue:

1. Use my forked version of `app_links` package and wait for my PR to be merged: https://github.com/llfbandit/app_links/pull/179

```yaml
dependencies:
  app_links:
    git:
      url: https://github.com/lijy91/app_links.git
```

> Note: This is a temporary solution, and I will remove this repository once my PR is merged.

2. Use [protocol_handler](https://github.com/leanflutter/protocol_handler) package instead of `app_links` package.

## Quick Start

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  tray_manager: ^0.3.0
```

Or

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: main
```

#### Linux requirements

- `ayatana-appindicator3-0.1` or `appindicator3-0.1`

Run the following command

```
sudo apt-get install libayatana-appindicator3-dev
```

Or

```
sudo apt-get install appindicator3-0.1 libappindicator3-dev
```

### Usage

```dart
import 'package:flutter/material.dart' hide MenuItem;
import 'package:tray_manager/tray_manager.dart';

await trayManager.setIcon(
  Platform.isWindows
    ? 'images/tray_icon.ico'
    : 'images/tray_icon.png',
);
Menu menu = Menu(
  items: [
    MenuItem(
      key: 'show_window',
      label: 'Show Window',
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'exit_app',
      label: 'Exit App',
    ),
  ],
);
await trayManager.setContextMenu(menu);
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
    trayManager.addListener(this);
    super.initState();
    _init();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
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
    // do something, for example pop up the menu
    trayManager.popUpContextMenu();
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

## Who's using it?

- [Airclap](https://airclap.app/) - Send any file to any device. cross platform, ultra fast and easy to use.
- [Biyi (比译)](https://biyidev.com/) - A convenient translation and dictionary app.

## API

### TrayManager

| Method           | Description                                    | Linux | macOS | Windows |
| ---------------- | ---------------------------------------------- | ----- | ----- | ------- |
| destroy          | Destroys the tray icon immediately.            | ✔️    | ✔️    | ✔️      |
| setIcon          | Sets the image associated with this tray icon. | ✔️    | ✔️    | ✔️      |
| setIconPosition  | Sets the icon position of the tray icon.       | ➖    | ✔️    | ➖      |
| setToolTip       | Sets the hover text for this tray icon.        | ➖    | ✔️    | ✔️      |
| setContextMenu   | Sets the context menu for this icon.           | ✔️    | ✔️    | ✔️      |
| popUpContextMenu | Pops up the context menu of the tray icon.     | ➖    | ✔️    | ✔️      |
| getBounds        | Returns `Rect` The bounds of this tray icon.   | ➖    | ✔️    | ✔️      |

## License

[MIT](./LICENSE)
