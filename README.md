> **tray_manager 0.6 is built on [nativeapi](https://github.com/libnativeapi/nativeapi-flutter)**, a
> Flutter binding of one C++ core library ([libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi))
> shared by macOS, Windows and Linux. Coming from 0.5.x? See [Upgrading from 0.5.x](#upgrading-from-05x).

# tray_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb

This package lets Flutter desktop apps put an icon, with a tooltip, a title and a context
menu, in the system tray.

English | [简体中文](./README-ZH.md)

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Platform Support](#platform-support)
- [Screenshots](#screenshots)
- [Known Issues](#known-issues)
  - [Not Showing in GNOME](#not-showing-in-gnome)
- [Quick Start](#quick-start)
  - [Installation](#installation)
    - [Requirements](#requirements)
  - [Usage](#usage)
    - [Upgrading from 0.5.x](#upgrading-from-05x)
    - [Moving to the native API](#moving-to-the-native-api)
- [Who's using it?](#whos-using-it)
- [API](#api)
  - [Native API](#native-api)
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

### Not Showing in GNOME

On Linux the tray icon is a StatusNotifierItem, which needs a panel that hosts them. KDE Plasma and most other desktops do; GNOME does only with the [AppIndicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) extension (Ubuntu ships it enabled).

## Quick Start

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  tray_manager: ^0.7.0
```

Or

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: main
```

#### Requirements

- Flutter 3.47 / Dart 3.13 or later, macOS 10.15 or later.
- Linux build machines need GTK 3, X11 and Xi development files. The tray icon is a
  StatusNotifierItem over D-Bus, so `libayatana-appindicator3-dev` is no longer needed.

```
sudo apt-get install libgtk-3-dev libx11-dev libxi-dev
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
package. Its classes are marked `@Deprecated` and **will be removed in a later
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

- Builds need Flutter 3.47 / Dart 3.13 and macOS 10.15 (0.5.x: Flutter 3.3, macOS 10.11).
- A click is reported when it completes, as `onTrayIconMouseDown` immediately followed by
  `onTrayIconMouseUp` (same for the right button). 0.5.x sent the two separately on macOS
  and only the first on Windows. Linux still reports no tray icon clicks at all: the
  panel keeps them and opens the menu itself.
- Calls a platform has no use for are ignored instead of throwing
  `MissingPluginException`: `setTitle` and `setIconPosition` on Windows; `setIconPosition`,
  `popUpContextMenu` and `getBounds` (which answers `null`) on Linux. `setToolTip` now
  works on Linux.
- `setIcon` throws an `ArgumentError` when the image cannot be loaded, on every
  platform. Windows takes `.png` as well as `.ico` now.
- `bringAppToFront` of `popUpContextMenu` is accepted but ignored.
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
| `MenuItem.checkbox(checked:)`, `disabled:`, `toolTip:` | `MenuItemType.checkbox` with `item.state` (set it yourself in the click listener; a click does not toggle it), `item.isEnabled`, `item.tooltip` |
| `MenuItem.submenu(submenu:)` | `MenuItemType.submenu` with `item.submenu = otherMenu` |
| `MenuItem(onClick:)`, `onTrayMenuItemClick` + `menuItem.key` | `item.addListener((event) { if (event is MenuItemClickedEvent) ... })` per item |
| `popUpContextMenu()` from `onTrayIconRightMouseDown` | `trayIcon.setContextMenuTrigger(ContextMenuTrigger.rightClicked)`, or `trayIcon.openContextMenu()` |
| `TrayListener` | `trayIcon.addListener((event) { switch (event) { case TrayIconClickedEvent(): ... } })` — also `TrayIconRightClickedEvent`, `TrayIconDoubleClickedEvent` (none of them on Linux) |
| `getBounds()` | `trayIcon.getBounds()` (synchronous; physical pixels on Windows, an empty `Rect` on Linux) |
| `destroy()` | `trayIcon.dispose()` |

Keep a reference to every `TrayIcon` for as long as it should be shown: a wrapper that is
garbage-collected releases its native handle, and that removes the icon. A `Menu` or
`MenuItem` that is attached stays alive natively, but keep the ones you want to change
later.

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
