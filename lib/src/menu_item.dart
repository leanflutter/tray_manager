import 'package:uuid/uuid.dart';

class MenuItem {
  String identifier = Uuid().v4();
  final String? title;
  final String? toolTip;
  final bool isEnabled;
  final bool isSeparatorItem;
  List<MenuItem> items = [];

  static final MenuItem separator = MenuItem(isSeparatorItem: true);

  MenuItem({
    String? identifier,
    this.title,
    this.toolTip,
    this.isEnabled = true,
    this.isSeparatorItem = false,
    List<MenuItem>? items,
  }) {
    if (identifier != null) this.identifier = identifier;
    if (items != null) this.items = items;
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'title': title ?? '',
      'toolTip': toolTip,
      'isEnabled': isEnabled,
      'isSeparatorItem': isSeparatorItem,
      'items': items.map((e) => e.toJson()).toList(),
    }..removeWhere((key, value) => value == null);
  }
}
