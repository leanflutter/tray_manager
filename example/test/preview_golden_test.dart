// The example shows the deprecated 0.5.x compatible API on purpose.
// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/legacy.dart' show TrayIconPosition;
import 'package:tray_manager_example/main.dart';
import 'package:tray_manager_example/tray_controller.dart';

// Renders the example window to test/goldens/*.png:
//
//   flutter test test/preview_golden_test.dart --update-goldens
//
// It draws with macOS system fonts and is only a picture generator, so without
// --update-goldens (CI) it is skipped instead of compared.

const _textFont = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
const _monoFont = '/System/Library/Fonts/Menlo.ttc';

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

void main() {
  final canRender =
      autoUpdateGoldenFiles &&
      File(_textFont).existsSync() &&
      File(_monoFont).existsSync();

  for (final brightness in Brightness.values) {
    testWidgets('example window, ${brightness.name}', (tester) async {
      await _loadFont('Preview', _textFont);
      await _loadFont('Menlo', _monoFont);

      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(840, 1200);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      // A state worth looking at, without touching the (absent) native tray.
      final controller = TrayController(autoCreate: false)
        ..created = true
        ..iconPath = kColourIcon
        ..isTemplate = false
        ..iconPosition = TrayIconPosition.right
        ..title = '42%'
        ..bounds = const Rect.fromLTWH(1093, 6, 54, 22);
      for (final event in const [
        'create  setIcon + setToolTip + setContextMenu',
        'setIcon  images/tray_icon_original.png',
        'setTitle  "42%"',
        'onTrayIconRightMouseDown',
        'onTrayMenuItemClick  notifications',
      ]) {
        controller.recordEvent(event);
      }

      await tester.pumpWidget(
        TrayManagerExampleApp(
          fontFamily: 'Preview',
          shell: Shell(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TrayManagerExampleApp),
        matchesGoldenFile('goldens/example_${brightness.name}.png'),
      );
    }, skip: !canRender);
  }
}
