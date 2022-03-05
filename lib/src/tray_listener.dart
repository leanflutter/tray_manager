import 'menu_item.dart';

abstract class TrayListener {
  /// Emitted when the mouse clicks the tray icon.
  void onTrayIconMouseDown() {}

  /// Emitted when the mouse is released from clicking the tray icon.
  void onTrayIconMouseUp() {}

  void onTrayIconRightMouseDown() {}

  void onTrayIconRightMouseUp() {}

  void onTrayMenuItemClick(MenuItem menuItem) {}
}
