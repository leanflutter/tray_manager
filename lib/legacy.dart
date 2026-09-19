/// The `tray_manager` API as it was before the move to nativeapi.
///
/// Existing apps keep working by importing this library instead of
/// `package:tray_manager/tray_manager.dart`. New code should use the native
/// API exported from there.
library;

export 'src/menu.dart' show Menu, MenuItem;
export 'src/tray_listener.dart';
export 'src/tray_manager.dart';
