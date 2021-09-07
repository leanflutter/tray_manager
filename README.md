# tray_manager

[![pub version][pub-image]][pub-url]

[pub-image]: https://img.shields.io/pub/v/tray_manager.svg
[pub-url]: https://pub.dev/packages/tray_manager

This plugin allows Flutter **desktop** apps to defines system tray.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [tray_manager](#tray_manager)
  - [Platform Support](#platform-support)
  - [Quick Start](#quick-start)
    - [Installation](#installation)
      - [⚠️ Linux requirements](#️-linux-requirements)
    - [Usage](#usage)
  - [API](#api)
    - [TrayManager](#traymanager)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Platform Support

| Linux | macOS | Windows |
| :---: | :---: | :-----: |
|   ✔️   |   ✔️   |    ➖    |

## Quick Start

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  tray_manager: ^0.0.1
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

await TrayManager.instance.setIcon('images/tray_icon.png');
List<MenuItem> menuItems = [
  MenuItem(title: 'Show/Hide Main Window'),
  MenuItem.separator,
  MenuItem(title: 'Exit App'),
];
await TrayManager.instance.setContextMenu(menuItems);
await TrayManager.instance.popUpContextMenu();
```

> Please see the example app of this plugin for a full example.

## API

### TrayManager

| Method           | Description                                    | Linux | macOS | Windows |
| ---------------- | ---------------------------------------------- | ----- | ----- | ------- |
| destroy          | Destroys the tray icon immediately.            | ➖     | ✔️     | ✔️       |
| setIcon          | Sets the image associated with this tray icon. | ➖     | ✔️     | ✔️       |
| setToolTip       | -                                              | ➖     | ✔️     | ➖       |
| setContextMenu   | -                                              | ➖     | ✔️     | ➖       |
| popUpContextMenu | -                                              | ➖     | ✔️     | ➖       |
| getBounds        | -                                              | ➖     | ✔️     | ✔️       |

## License

```text
MIT License

Copyright (c) 2021 LiJianying <lijy91@foxmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
