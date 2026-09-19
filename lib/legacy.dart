// ignore_for_file: deprecated_member_use_from_same_package

/// The `tray_manager` API as it was before the move to nativeapi.
///
/// Existing apps keep working by importing this library instead of
/// `package:tray_manager/tray_manager.dart`. The changed import is deliberate:
/// this API is a bridge, its classes are deprecated, and it will be removed
/// in a future release. New code should use the native API exported from
/// `package:tray_manager/tray_manager.dart`.
library;

export 'src/menu.dart' show Menu, MenuItem;
export 'src/menu_behavior.dart';
export 'src/tray_listener.dart';
export 'src/tray_manager.dart';
