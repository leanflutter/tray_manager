import 'package:tray_manager/src/menu.dart';

abstract mixin class TrayListener {
  void onTrayIconMouseDown() {}

  void onTrayIconMouseUp() {}

  void onTrayIconRightMouseDown() {}

  void onTrayIconRightMouseUp() {}

  void onTrayMenuItemClick(MenuItem menuItem) {}
}
