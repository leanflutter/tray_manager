> **tray_manager 0.6 is built on [nativeapi](https://github.com/libnativeapi/nativeapi-flutter)**, a
> Flutter binding of one C++ core library ([libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi))
> shared by macOS, Windows and Linux. Coming from 0.5.x? See [Upgrading from 0.5.x](#upgrading-from-05x).

# tray_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb

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
    - [Requirements](#requirements)
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
  tray_manager: ^0.6.0
```

Or

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: dev
```

#### Requirements

- Flutter 3.35 / Dart 3.9 or later, macOS 10.15 or later.
- Linux build machines need GTK 3, X11 and Xi development files — and, with nativeapi
  0.2.7, still `libayatana-appindicator3-dev`. The tray icon is a StatusNotifierItem and
  nothing uses that library any more; the requirement is a leftover in nativeapi's build
  file and goes away with its next release.

```
sudo apt-get install libgtk-3-dev libx11-dev libxi-dev libayatana-appindicator3-dev
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

> The [example app](./example) of this plugin covers the 0.5.x compatible API. For the
> full example — several icons, animated icons, every native property — see nativeapi's
> [tray_icon_example](https://github.com/libnativeapi/nativeapi-flutter/tree/main/examples/tray_icon_example).

#### Upgrading from 0.5.x

Code written for `tray_manager` 0.5.x keeps working by importing
`package:tray_manager/legacy.dart` instead of `package:tray_manager/tray_manager.dart`.
It provides the old `trayManager`, `TrayListener`, `Menu` and `MenuItem`
(`menu_base` is no longer a dependency) on top of the native API.

The import has to change on purpose: `legacy.dart` is a bridge, not the future of this
package. Everything in it is marked `@Deprecated` and **will be removed in a later
release** — move to the native API above when you can.

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

- Builds need Flutter 3.35 / Dart 3.9 and macOS 10.15 (0.5.x: Flutter 3.3, macOS 10.11).
- `onTrayIconMouseDown` and `onTrayIconMouseUp` now both arrive on Windows (0.5.x only
  sent the first) and, new, on Linux, where the panel used to keep every click for
  itself.
- `setToolTip`, `popUpContextMenu`, `getBounds` and `setIconPosition` no longer throw
  `MissingPluginException` on Linux; `getBounds` answers `null` there and
  `popUpContextMenu` does nothing, because only the panel can open the menu.
- `setIcon` throws an `ArgumentError` when the image cannot be loaded, on every
  platform. Windows takes `.png` as well as `.ico` now.
- `bringAppToFront` of `popUpContextMenu` is accepted but ignored.
- `onTrayIconMouseDown` / `onTrayIconMouseUp` (and the right-button pair) are
  both delivered when the click completes.
- `MenuItem.onClick` runs once per click, also when no `TrayListener` is
  registered.
- `label`, `toolTip`, `checked` and `disabled` of a `MenuItem` update the
  visible menu as soon as they are assigned; adding or removing items still
  needs another `setContextMenu` call.
- `sublabel`, `onHighlight` and `onLoseHighlight` are kept but unused.

#### Moving to the native API

| 0.5.x (`legacy.dart`) | Native API (`tray_manager.dart`) |
| --- | --- |
| `trayManager` (one icon per app) | `TrayIcon.create()` — as many as you need; keep the object, `dispose()` it when done |
| `setIcon('images/icon.png')` | `trayIcon.icon = ImageAsset.fromAsset('images/icon.png')` (also `Image.fromFile`, `Image.fromBase64`) |
| `setIcon(isTemplate:, iconSize:, iconPosition:)`, `setIconPosition` | `trayIcon.isIconTemplate`, `trayIcon.iconSize`, `trayIcon.iconPosition` |
| `setToolTip(text)` / `setTitle(text)` | `trayIcon.setTooltip(text)` / `trayIcon.setTitle(text)` — `null` clears; `getTooltip()` / `getTitle()` read back |
| `setContextMenu(Menu(items: [...]))` | `Menu.create()`, `menu.addItem(MenuItem.createWithLabelAndType(label, MenuItemType.normal))`, `menu.addSeparator()`, then `trayIcon.setContextMenu(menu)` |
| `MenuItem.checkbox(checked:)`, `disabled:`, `toolTip:` | `MenuItemType.checkbox` with `item.state`, `item.isEnabled`, `item.tooltip` |
| `MenuItem.submenu(submenu:)` | `MenuItemType.submenu` with `item.submenu = otherMenu` |
| `MenuItem(onClick:)`, `onTrayMenuItemClick` + `menuItem.key` | `item.addListener((event) { if (event is MenuItemClickedEvent) ... })` per item |
| `popUpContextMenu()` from `onTrayIconRightMouseDown` | `trayIcon.setContextMenuTrigger(ContextMenuTrigger.rightClicked)`, or `trayIcon.openContextMenu()` |
| `TrayListener` | `trayIcon.addListener((event) { switch (event) { case TrayIconClickedEvent(): ... } })` — also `TrayIconRightClickedEvent`, `TrayIconDoubleClickedEvent` |
| `getBounds()` | `trayIcon.getBounds()` (synchronous; physical pixels on Windows) |
| `destroy()` | `trayIcon.dispose()` |

Keep a reference to every `TrayIcon`, `Menu` and `MenuItem` you create for as long as it
is in use: a wrapper that is garbage-collected releases its native handle — for a `TrayIcon` that
removes the icon.

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
