import 'package:uuid/uuid.dart';

class MenuItem {
  int id = -1;
  String key = Uuid().v4();
  final String? title;
  final String? toolTip;
  final bool isEnabled;
  final bool isSeparatorItem;
  List<MenuItem> items = [];

  static final MenuItem separator = MenuItem(isSeparatorItem: true);

  MenuItem({
    String? key,
    this.title,
    this.toolTip,
    this.isEnabled = true,
    this.isSeparatorItem = false,
    List<MenuItem>? items,
  }) {
    if (key != null) this.key = key;
    if (items != null) this.items = items;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'title': title ?? '',
      'toolTip': toolTip,
      'isEnabled': isEnabled,
      'isSeparatorItem': isSeparatorItem,
      'items': items.map((e) => e.toJson()).toList(),
    }..removeWhere((key, value) => value == null);
  }
}
