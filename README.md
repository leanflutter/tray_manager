> **⚠️ Migration Notice**: This plugin is being migrated to [libnativeapi/nativeapi-flutter](https://github.com/libnativeapi/nativeapi-flutter)
>
> The new version is based on a unified C++ core library ([libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi)), providing more complete and consistent cross-platform native API support.
r

# tray_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url] ![][visits-count-image]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb
[visits-count-image]: https://img.shields.io/badge/dynamic/json?label=Visits%20Count&query=value&url=https://api.countapi.xyz/hit/leanflutter.tray_manager/visits

This plugin allows Flutter desktop apps to defines system tray.

English | [简体中文](./README-ZH.md)

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Platform Support](#platform-support)
- [Screenshots](#screenshots)
- [Known Issues](#known-issues)
  - [Not Working with app_links](#not-working-with-app_links)
  - [Not Showing in GNOME](#not-showing-in-gnome)
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

When using the `app_links` package together with `tray_manager`, the plugin may not work properly. This is because older versions of `app_links` internally block event propagation, preventing menu click events from being triggered.

To resolve this issue:

1. Make sure your `app_links` package version is greater than or equal to 6.3.3

```yaml
dependencies:
  app_links: ^6.3.3
```

2. Use [protocol_handler](https://github.com/leanflutter/protocol_handler) package instead of `app_links` package.

### Not Showing in GNOME

In GNOME desktop environment, the [AppIndicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) extension may be required to display the icon.

## Quick Start

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  tray_manager: ^0.5.2
```

Or

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: next
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
import 'package:tray_manager/tray_manager.dart';

final trayIcon = TrayIcon.create()!;
trayIcon.icon = ImageAsset.fromAsset('images/tray_icon.png');
trayIcon.setTooltip('tray_manager');

final menu = Menu.create()!;
final showWindowItem = MenuItem.createWithLabelAndType(
  'Show Window',
  MenuItemType.normal,
)!;
showWindowItem.addListener((event) {
  if (event is MenuItemClickedEvent) {
    // Show the application window.
  }
});
menu.addItem(showWindowItem);
menu.addSeparator();
menu.addItem(MenuItem.createWithLabelAndType('Exit App', MenuItemType.normal));

trayIcon.setContextMenu(menu);
trayIcon.setVisible(true);
```

> Please see the example app of this plugin for a full example.

#### Upgrading from 0.5.x

Code written for `tray_manager` 0.5.x keeps working by importing
`package:tray_manager/legacy.dart` instead of `package:tray_manager/tray_manager.dart`.
It provides the old `trayManager`, `TrayListener`, `Menu` and `MenuItem`
(`menu_base` is no longer a dependency) on top of the native API.

```dart
import 'package:tray_manager/legacy.dart';

await trayManager.setIcon('images/tray_icon.png');
await trayManager.setToolTip('tray_manager');
await trayManager.setContextMenu(
  Menu(
    items: [
      MenuItem(key: 'show_window', label: 'Show Window'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: 'Exit App'),
    ],
  ),
);
```

What differs from 0.5.x:

- `bringAppToFront` of `popUpContextMenu` is accepted but ignored.
- `onTrayIconMouseDown` / `onTrayIconMouseUp` (and the right-button pair) are
  both delivered when the click completes.
- `MenuItem.onClick` runs once per click, also when no `TrayListener` is
  registered.
- `label`, `toolTip`, `checked` and `disabled` of a `MenuItem` update the
  visible menu as soon as they are assigned; adding or removing items still
  needs another `setContextMenu` call.
- `sublabel`, `onHighlight` and `onLoseHighlight` are kept but unused.

## Who's using it?

- [Airclap](https://airclap.app/) - Send any file to any device. cross platform, ultra fast and easy to use.
- [Biyi (比译)](https://biyidev.com/) - A convenient translation and dictionary app.
- [scrcpy buddy 🤝](https://github.com/Codertainment/scrcpy_buddy) - A GUI for [scrcpy](https://github.com/Genymobile/scrcpy) built with Fluent Design.

## API

### Native API

`tray_manager` now re-exports tray-related APIs from `nativeapi`, including
`TrayIcon`, `TrayManager`, `Menu`, `MenuItem`, `Image`, and tray/menu events.
Import `package:tray_manager/legacy.dart` only for code that still uses the
0.5.x API.

## License

[MIT](./LICENSE)
