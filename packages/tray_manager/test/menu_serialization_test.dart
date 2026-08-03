import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/src/menu_serialization.dart';
import 'package:tray_manager/tray_manager.dart';

void main() {
  test('embeds macOS asset icons and caches repeated nested icons', () async {
    var loadCount = 0;
    final menu = Menu(
      items: [
        MenuItem(label: 'Top level', icon: 'images/icon.png'),
        MenuItem.submenu(
          label: 'Submenu',
          submenu: Menu(
            items: [MenuItem(label: 'Nested', icon: 'images/icon.png')],
          ),
        ),
      ],
    );

    final json = await serializeMenuForPlatform(
      menu,
      platform: TargetPlatform.macOS,
      loadAsset: (key) async {
        loadCount++;
        return ByteData.sublistView(Uint8List.fromList([9, 1, 2, 3, 9]), 1, 4);
      },
    );

    final items = json['items']! as List<Map<String, dynamic>>;
    final nested = (items[1]['submenu']! as Map<String, dynamic>)['items']!
        as List<Map<String, dynamic>>;
    expect(items[0]['base64Icon'], base64Encode([1, 2, 3]));
    expect(nested[0]['base64Icon'], base64Encode([1, 2, 3]));
    expect(loadCount, 1);
  });

  test('ignores empty icon values', () async {
    var loadCount = 0;
    final menu = Menu(items: [MenuItem(label: 'Item', icon: '')]);

    final json = await serializeMenuForPlatform(
      menu,
      platform: TargetPlatform.macOS,
      loadAsset: (_) async {
        loadCount++;
        return ByteData(0);
      },
    );

    final item = (json['items']! as List<Map<String, dynamic>>).single;
    expect(item, isNot(contains('base64Icon')));
    expect(loadCount, 0);
  });

  test('keeps an invalid icon path for the native file fallback', () async {
    final menu = Menu(
      items: [MenuItem(label: 'File', icon: '/tmp/icon.png')],
    );

    final json = await serializeMenuForPlatform(
      menu,
      platform: TargetPlatform.macOS,
      loadAsset: (_) => Future<ByteData>.error(StateError('not an asset')),
    );

    final item = (json['items']! as List<Map<String, dynamic>>).single;
    expect(item['icon'], '/tmp/icon.png');
    expect(item, isNot(contains('base64Icon')));
  });

  test('does not load or alter icons on other platforms', () async {
    var loadCount = 0;
    final menu = Menu(
      items: [MenuItem(label: 'Item', icon: 'images/icon.png')],
    );

    final json = await serializeMenuForPlatform(
      menu,
      platform: TargetPlatform.windows,
      loadAsset: (_) async {
        loadCount++;
        return ByteData(0);
      },
    );

    expect(json, menu.toJson());
    expect(loadCount, 0);
  });
}
