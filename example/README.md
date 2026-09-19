# tray_manager_example

`tray_manager` through its 0.5.x compatible API (`package:tray_manager/legacy.dart`):
one tray icon driven by the classic `trayManager` calls and a `TrayListener`.

That API is deprecated and will be removed in a later release; it is shown here for apps
that are still on their way to the native API.

- `lib/tray_controller.dart` — every `trayManager` call, the context menu, the listener
- `lib/main.dart`, `lib/widgets/` — the window: one row of choices per API, the
  bounds read back from the system, and a log of the listener callbacks. Built on
  `package:flutter/widgets.dart` alone.

```sh
flutter run -d macos
flutter run -d linux
flutter run -d windows
```

## Looking for the full example?

This one is deliberately small. Several icons at once, animated icons, every native
property with read-back, and an acceptance checklist are in nativeapi's
[tray_icon_example](https://github.com/libnativeapi/nativeapi-flutter/tree/main/examples/tray_icon_example).
