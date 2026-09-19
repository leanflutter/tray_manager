// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:ui';

import 'package:tray_manager/src/menu.dart';

// tray_manager 0.5.x re-exported all of menu_base, so these two names were part
// of its API. Nothing in tray_manager ever used them; they are here so that
// code mentioning them still compiles.

@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
enum Placement { topLeft, topRight, bottomLeft, bottomRight }

@Deprecated(
  'The 0.5.x compatible API will be removed in a future release. Use the native API from package:tray_manager/tray_manager.dart.',
)
abstract class MenuBehavior {
  Future<void> popUp(
    Menu menu, {
    Offset? position,
    Placement placement = Placement.topLeft,
  });
}
