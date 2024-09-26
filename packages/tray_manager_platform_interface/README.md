# tray_manager_platform_interface

[![pub version][pub-image]][pub-url]

[pub-image]: https://img.shields.io/pub/v/tray_manager_platform_interface.svg
[pub-url]: https://pub.dev/packages/tray_manager_platform_interface

A common platform interface for the [tray_manager](https://pub.dev/packages/tray_manager) plugin.

## Usage

To implement a new platform-specific implementation of tray_manager, extend `TrayManagerPlatform` with an implementation that performs the platform-specific behavior, and when you register your plugin, set the default `TrayManagerPlatform` by calling `TrayManagerPlatform.instance = MyPlatformTrayManager()`.

## License

[MIT](./LICENSE)
