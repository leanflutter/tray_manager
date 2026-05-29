import 'package:nativeapi/nativeapi.dart' as nativeapi;

abstract mixin class TrayListener {
  void onTrayIconMouseDown() {}

  void onTrayIconMouseUp() {}

  void onTrayIconRightMouseDown() {}

  void onTrayIconRightMouseUp() {}

  void onTrayMenuItemClick(nativeapi.MenuItem menuItem) {}
}
