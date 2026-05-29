> **⚠️ 迁移通知**: 本插件正在迁移到 [libnativeapi/nativeapi-flutter](https://github.com/libnativeapi/nativeapi-flutter)
>
> 新版本基于统一的 C++ 核心库（[libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi)），提供更完整、一致的跨平台原生 API 支持。

# tray_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url] ![][visits-count-image]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager
[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb
[visits-count-image]: https://img.shields.io/badge/dynamic/json?label=Visits%20Count&query=value&url=https://api.countapi.xyz/hit/leanflutter.tray_manager/visits

这个插件允许 Flutter 桌面应用定义系统托盘。

[English](./README.md) | 简体中文

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [平台支持](#%E5%B9%B3%E5%8F%B0%E6%94%AF%E6%8C%81)
- [截图](#%E6%88%AA%E5%9B%BE)
- [已知问题](#%E5%B7%B2%E7%9F%A5%E9%97%AE%E9%A2%98)
  - [与 app_links 不兼容](#%E4%B8%8E-app_links-%E4%B8%8D%E5%85%BC%E5%AE%B9)
  - [在 GNOME 中不显示](#%E5%9C%A8-gnome-%E4%B8%AD%E4%B8%8D%E6%98%BE%E7%A4%BA)
- [快速开始](#%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B)
  - [安装](#%E5%AE%89%E8%A3%85)
    - [Linux requirements](#linux-requirements)
  - [用法](#%E7%94%A8%E6%B3%95)
    - [监听事件](#%E7%9B%91%E5%90%AC%E4%BA%8B%E4%BB%B6)
- [谁在用使用它？](#%E8%B0%81%E5%9C%A8%E7%94%A8%E4%BD%BF%E7%94%A8%E5%AE%83)
- [API](#api)
  - [TrayManager](#traymanager)
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

### 与 app_links 不兼容

当同时使用 `app_links` 包和 `tray_manager` 时，可能会出现插件无法正常工作。这是因为低版本 `app_links` 在内部阻止了事件传播，导致菜单点击事件无法触发。

要解决此问题：

1. 确保你的 `app_links` 包版本大于或等于 6.3.3

```yaml
dependencies:
  app_links: ^6.3.3
```

2. 使用 [protocol_handler](https://github.com/leanflutter/protocol_handler) 包代替 `app_links` 包。

### 在 GNOME 中不显示

在使用 GNOME 桌面时, 可能需要安装 [AppIndicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) 扩展以显示图标。

## 快速开始

### 安装

将此添加到你的软件包的 pubspec.yaml 文件：

```yaml
dependencies:
  tray_manager: ^0.5.2
```

或

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: next
```

#### Linux requirements

- `ayatana-appindicator3-0.1` or `appindicator3-0.1`

运行以下命令

```
sudo apt-get install libayatana-appindicator3-dev
```

或

```
sudo apt-get install appindicator3-0.1 libappindicator3-dev
```

### 用法

```dart
import 'package:tray_manager/tray_manager.dart';

final trayIcon = TrayIcon();
trayIcon.icon = Image.fromAsset('images/tray_icon.png');
trayIcon.tooltip = 'tray_manager';

final menu = Menu();
final showWindowItem = MenuItem('Show Window');
showWindowItem.on<MenuItemClickedEvent>((event) {
  // 显示应用窗口。
});
menu.addItem(showWindowItem);
menu.addSeparator();
menu.addItem(MenuItem('Exit App'));

trayIcon.contextMenu = menu;
trayIcon.isVisible = true;
```

> 请看这个插件的示例应用，以了解完整的例子。

#### 旧方法名兼容

```dart
import 'package:tray_manager/legacy.dart';

await LegacyTrayManager.instance.setIcon('images/tray_icon.png');
await LegacyTrayManager.instance.setToolTip('tray_manager');
await LegacyTrayManager.instance.setContextMenu(menu);
await LegacyTrayManager.instance.popUpContextMenu();
```

## 谁在用使用它？

- [Airclap](https://airclap.app/) - 任何文件，任意设备，随意发送。简单好用的跨平台高速文件传输 APP。
- [Biyi (比译)](https://biyidev.com/) - 一个便捷的翻译和词典应用程序。

## API

### Native API

`tray_manager` 现在重新导出 `nativeapi` 中的托盘相关 API，包括 `TrayIcon`、
`TrayManager`、`Menu`、`MenuItem`、`Image` 以及托盘和菜单事件。
迁移仍调用旧方法名的代码时，使用 `LegacyTrayManager`。

## 许可证

[MIT](./LICENSE)
