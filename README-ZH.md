> **tray_manager 0.6 基于 [nativeapi](https://github.com/libnativeapi/nativeapi-flutter) 构建**——它是统一的
> C++ 核心库（[libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi)）的 Flutter 绑定，macOS、Windows、Linux
> 共用同一套实现。从 0.5.x 升级？请看[从 0.5.x 升级](#从-05x-升级)。

# tray_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb

这个包让 Flutter 桌面应用在系统托盘中放置图标，并为它设置提示、标题和右键菜单。

[English](./README.md) | 简体中文

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [平台支持](#%E5%B9%B3%E5%8F%B0%E6%94%AF%E6%8C%81)
- [截图](#%E6%88%AA%E5%9B%BE)
- [已知问题](#%E5%B7%B2%E7%9F%A5%E9%97%AE%E9%A2%98)
  - [在 GNOME 中不显示](#%E5%9C%A8-gnome-%E4%B8%AD%E4%B8%8D%E6%98%BE%E7%A4%BA)
- [快速开始](#%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B)
  - [安装](#%E5%AE%89%E8%A3%85)
    - [环境要求](#%E7%8E%AF%E5%A2%83%E8%A6%81%E6%B1%82)
  - [用法](#%E7%94%A8%E6%B3%95)
    - [从 0.5.x 升级](#%E4%BB%8E-05x-%E5%8D%87%E7%BA%A7)
    - [迁移到原生 API](#%E8%BF%81%E7%A7%BB%E5%88%B0%E5%8E%9F%E7%94%9F-api)
- [谁在使用它？](#%E8%B0%81%E5%9C%A8%E4%BD%BF%E7%94%A8%E5%AE%83)
- [API](#api)
  - [Native API](#native-api)
- [许可证](#%E8%AE%B8%E5%8F%AF%E8%AF%81)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 平台支持

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|  ✔️   |  ✔️   |   ✔️    |

## 截图

| macOS                                                                                     | Linux                                                                                     | Windows                                                                                          |
| ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| ![](https://github.com/leanflutter/tray_manager/blob/main/screenshots/macos.png?raw=true) | ![](https://github.com/leanflutter/tray_manager/blob/main/screenshots/linux.png?raw=true) | ![image](https://github.com/leanflutter/tray_manager/blob/main/screenshots/windows.png?raw=true) |

## 已知问题

### 在 GNOME 中不显示

Linux 上的托盘图标是 StatusNotifierItem，需要面板支持才能显示。KDE Plasma 和大多数桌面都支持；GNOME 需要安装 [AppIndicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) 扩展（Ubuntu 默认已启用）。

## 快速开始

### 安装

将此添加到你的软件包的 pubspec.yaml 文件：

```yaml
dependencies:
  tray_manager: ^0.6.0
```

或

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: main
```

#### 环境要求

- Flutter 3.35 / Dart 3.9 及以上，macOS 10.15 及以上。
- Linux 构建机需要 GTK 3、X11、Xi 的开发文件；在 nativeapi 0.2.7 下还需要
  `libayatana-appindicator3-dev`。托盘图标现在是 StatusNotifierItem，已经没有代码使用这个库，
  这只是 nativeapi 构建文件里的残留，会随它的下一个版本去掉。

```
sudo apt-get install libgtk-3-dev libx11-dev libxi-dev libayatana-appindicator3-dev
```

### 用法

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

> 本插件的[示例应用](./example)演示的是与 0.5.x 兼容的 API。完整示例（多个图标、动画图标、全部原生属性）请看 nativeapi 的
> [tray_icon_example](https://github.com/libnativeapi/nativeapi-flutter/tree/main/examples/tray_icon_example)。

#### 从 0.5.x 升级

为 `tray_manager` 0.5.x 编写的代码，只需把导入从
`package:tray_manager/tray_manager.dart` 改为 `package:tray_manager/legacy.dart` 即可继续使用。
该库在原生 API 之上提供旧版的 `trayManager`、`TrayListener`、`Menu` 和 `MenuItem`
（不再依赖 `menu_base`）。

需要改 import 是有意为之：`legacy.dart` 只是过渡用的桥，不是这个包的未来。其中的类都已标记
`@Deprecated`，**会在后续版本中移除**——请尽早迁移到上面的原生 API。

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

与 0.5.x 的差异：

- 构建需要 Flutter 3.35 / Dart 3.9 和 macOS 10.15（0.5.x 为 Flutter 3.3、macOS 10.11）。
- 点击在完成时上报：`onTrayIconMouseDown` 之后紧跟 `onTrayIconMouseUp`（右键同理）。0.5.x 在 macOS
  上分两次发，在 Windows 上只发前者。Linux 上仍然没有任何托盘图标点击事件：点击由面板自己处理并打开菜单。
- 平台用不上的调用会被忽略，不再抛 `MissingPluginException`：Windows 上的 `setTitle`、`setIconPosition`；
  Linux 上的 `setIconPosition`、`popUpContextMenu` 和 `getBounds`（返回 `null`）。`setToolTip` 现在在
  Linux 上可用。
- 图片加载失败时，`setIcon` 在所有平台上都抛 `ArgumentError`。Windows 现在除 `.ico` 外也接受 `.png`。
- `popUpContextMenu` 的 `bringAppToFront` 仍可传入，但会被忽略。
- `MenuItem.onClick` 每次点击只调用一次，没有注册 `TrayListener` 时也会调用。
- 给 `MenuItem` 的 `label`、`toolTip`、`checked`、`disabled` 赋值会立即更新已显示的菜单；
  增删菜单项仍需再次调用 `setContextMenu`。
- `sublabel`、`onHighlight`、`onLoseHighlight` 仅为兼容保留，不再生效。

#### 迁移到原生 API

| 0.5.x（`legacy.dart`） | 原生 API（`tray_manager.dart`） |
| --- | --- |
| `trayManager`（每个应用一个图标） | `TrayIcon.create()`——需要几个建几个；保留对象，用完 `dispose()` |
| `setIcon('images/icon.png')` | `trayIcon.icon = ImageAsset.fromAsset('images/icon.png')`（另有 `Image.fromFile`、`Image.fromBase64`） |
| `setIcon(isTemplate:, iconSize:, iconPosition:)`、`setIconPosition` | `trayIcon.isIconTemplate`、`trayIcon.iconSize`、`trayIcon.iconPosition` |
| `setToolTip(text)` / `setTitle(text)` | `trayIcon.setTooltip(text)` / `trayIcon.setTitle(text)`——传 `null` 清除；`getTooltip()` / `getTitle()` 可读回 |
| `setContextMenu(Menu(items: [...]))` | `Menu.create()`、`menu.addItem(MenuItem.createWithLabelAndType(label, MenuItemType.normal))`、`menu.addSeparator()`，然后 `trayIcon.setContextMenu(menu)` |
| `MenuItem.checkbox(checked:)`、`disabled:`、`toolTip:` | `MenuItemType.checkbox` 配合 `item.state`（需在点击监听里自己设置，点击不会自动切换），以及 `item.isEnabled`、`item.tooltip` |
| `MenuItem.submenu(submenu:)` | `MenuItemType.submenu` 配合 `item.submenu = otherMenu` |
| `MenuItem(onClick:)`、`onTrayMenuItemClick` + `menuItem.key` | 每个菜单项 `item.addListener((event) { if (event is MenuItemClickedEvent) ... })` |
| 在 `onTrayIconRightMouseDown` 里 `popUpContextMenu()` | `trayIcon.setContextMenuTrigger(ContextMenuTrigger.rightClicked)`，或 `trayIcon.openContextMenu()` |
| `TrayListener` | `trayIcon.addListener((event) { switch (event) { case TrayIconClickedEvent(): ... } })`——另有 `TrayIconRightClickedEvent`、`TrayIconDoubleClickedEvent`（Linux 上都没有） |
| `getBounds()` | `trayIcon.getBounds()`（同步；Windows 上是物理像素，Linux 上是空 `Rect`） |
| `destroy()` | `trayIcon.dispose()` |

每个 `TrayIcon` 在需要显示期间都要保留引用：包装对象被垃圾回收时会释放原生句柄，图标随之消失。已挂上去的
`Menu` 和 `MenuItem` 在原生侧会继续存活，但之后还想修改的那些要自己留着。

## 谁在使用它？

- [Airclap](https://airclap.app/) - 任何文件，任意设备，随意发送。简单好用的跨平台高速文件传输 APP。
- [Biyi (比译)](https://biyidev.com/) - 一个便捷的翻译和词典应用程序。

## API

### Native API

`tray_manager` 现在重新导出 `nativeapi` 中的托盘相关 API，包括 `TrayIcon`、
`TrayManager`、`Menu`、`MenuItem`、`Image` 以及托盘和菜单事件。
仅在代码仍使用 0.5.x API 时导入 `package:tray_manager/legacy.dart`。

## 许可证

[MIT](./LICENSE)
