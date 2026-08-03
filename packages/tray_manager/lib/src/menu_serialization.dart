import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:menu_base/menu_base.dart';

typedef MenuIconAssetLoader = Future<ByteData> Function(String key);

/// Internal platform-aware serialization for native tray menus.
Future<Map<String, dynamic>> serializeMenuForPlatform(
  Menu menu, {
  TargetPlatform? platform,
  MenuIconAssetLoader? loadAsset,
}) async {
  if ((platform ?? defaultTargetPlatform) != TargetPlatform.macOS) {
    return menu.toJson();
  }

  return _serializeMenuWithIcons(
    menu,
    <String, String>{},
    loadAsset ?? rootBundle.load,
  );
}

Future<Map<String, dynamic>> _serializeMenuWithIcons(
  Menu menu,
  Map<String, String> iconCache,
  MenuIconAssetLoader loadAsset,
) async {
  final jsonItems = <Map<String, dynamic>>[];

  for (final item in menu.items ?? const <MenuItem>[]) {
    final jsonItem = Map<String, dynamic>.from(item.toJson());
    final iconPath = item.icon;

    if (iconPath != null && iconPath.isNotEmpty) {
      var base64Icon = iconCache[iconPath];
      if (base64Icon == null) {
        try {
          final data = await loadAsset(iconPath);
          base64Icon = base64Encode(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
          iconCache[iconPath] = base64Icon;
        } catch (_) {
          // Keep the original icon path so native code can try loading it as
          // an absolute file path.
        }
      }
      if (base64Icon != null) {
        jsonItem['base64Icon'] = base64Icon;
      }
    }

    if (item.submenu case final submenu?) {
      jsonItem['submenu'] = await _serializeMenuWithIcons(
        submenu,
        iconCache,
        loadAsset,
      );
    }
    jsonItems.add(jsonItem);
  }

  return <String, dynamic>{'items': jsonItems};
}
