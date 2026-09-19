// ignore_for_file: deprecated_member_use_from_same_package

import 'package:tray_manager/src/menu.dart';

@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
abstract mixin class TrayListener {
  void onTrayIconMouseDown() {}

  void onTrayIconMouseUp() {}

  void onTrayIconRightMouseDown() {}

  void onTrayIconRightMouseUp() {}

  void onTrayMenuItemClick(MenuItem menuItem) {}
}
