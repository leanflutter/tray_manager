import 'package:menu_base/menu_base.dart';

abstract class TrayListener {
  /// Emitted when the mouse clicks the tray icon.
  void onTrayIconMouseDown() {}

  /// Emitted when the mouse is released from clicking the tray icon.
  void onTrayIconMouseUp() {}

  void onTrayIconRightMouseDown() {}

  void onTrayIconRightMouseUp() {}

  void onTrayMenuItemClick(MenuItem menuItem) {}

  /// Emitted when windows taskbar created, such as explorer.exe restarted
  void onWindowsTaskbarCreated() {}
}
