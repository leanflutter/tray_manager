# tray_manager

[![pub version][pub-image]][pub-url] [![][discord-image]][discord-url]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager

[discord-image]: https://img.shields.io/discord/884679008049037342.svg
[discord-url]: https://discord.gg/zPa6EZ2jqb

这个插件允许 Flutter **桌面** 应用定义系统托盘。

---

[English](./README.md) | 简体中文

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [hotkey_manager](#hotkey_manager)
  - [平台支持](#平台支持)
  - [快速开始](#快速开始)
    - [安装](#安装)
      - [⚠️ Linux requirements](#️-linux-requirements)
    - [用法](#用法)
      - [Listening events](#listening-events)
  - [谁在用使用它？](#谁在用使用它)
  - [API](#api)
    - [TrayManager](#traymanager)
  - [许可证](#许可证)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 平台支持

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|   ✔️   |   ✔️   |    ✔️    |

## 快速开始

### 安装

将此添加到你的软件包的 pubspec.yaml 文件：

```yaml
dependencies:
  tray_manager: ^0.1.2
```

或

```yaml
dependencies:
  tray_manager:
    git:
      url: https://github.com/leanflutter/tray_manager.git
      ref: main
```

#### ⚠️ Linux requirements

- `appindicator3-0.1`

运行以下命令

```
sudo apt-get install appindicator3-0.1 libappindicator3-dev
```

### 用法

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

> 请看这个插件的示例应用，以了解完整的例子。

#### 监听事件

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

## 谁在用使用它？

- [Biyi (比译)](https://biyidev.com/) - 一个便捷的翻译和词典应用程序。

## API

### TrayManager

| Method           | Description                      | Linux | macOS | Windows |
| ---------------- | -------------------------------- | ----- | ----- | ------- |
| destroy          | 立即销毁托盘图标                 | ✔️     | ✔️     | ✔️       |
| setIcon          | 设置与此托盘图标相关的图片。     | ✔️     | ✔️     | ✔️       |
| setContextMenu   | -                                | ✔️     | ✔️     | ✔️       |
| popUpContextMenu | 弹出托盘图标的上下文菜单。       | ➖     | ✔️     | ✔️       |
| getBounds        | 返回 `Rect` 这个托盘图标的边界。 | ✔️     | ✔️     | ✔️       |

## 许可证

[MIT](./LICENSE)
