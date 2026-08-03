import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/tray_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const trayChannel = MethodChannel('tray_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMessageHandler('flutter/assets', null);
    messenger.setMockMethodCallHandler(trayChannel, null);
  });

  test('a slow icon load cannot replace a newer context menu', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final assetLoads = <String, Completer<ByteData>>{};
    final receivedMenus = <Map<dynamic, dynamic>>[];

    messenger.setMockMessageHandler('flutter/assets', (message) {
      final key = utf8.decode(message!.buffer.asUint8List());
      final completer = Completer<ByteData>();
      assetLoads[key] = completer;
      return completer.future;
    });
    messenger.setMockMethodCallHandler(trayChannel, (call) async {
      if (call.method == 'setContextMenu') {
        final arguments = call.arguments as Map<dynamic, dynamic>;
        receivedMenus.add(arguments['menu'] as Map<dynamic, dynamic>);
      }
      return null;
    });

    final first = trayManager.setContextMenu(
      Menu(items: [MenuItem(label: 'First', icon: 'first.png')]),
    );
    final second = trayManager.setContextMenu(
      Menu(items: [MenuItem(label: 'Second', icon: 'second.png')]),
    );
    await Future<void>.delayed(Duration.zero);

    assetLoads['second.png']!.complete(ByteData(1));
    await second;
    assetLoads['first.png']!.complete(ByteData(1));
    await first;

    expect(receivedMenus, hasLength(1));
    final items = receivedMenus.single['items'] as List<dynamic>;
    expect((items.single as Map<dynamic, dynamic>)['label'], 'Second');
  });
}
