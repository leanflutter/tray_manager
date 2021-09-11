import 'package:uuid/uuid.dart';

class MenuItem {
  String identifier = Uuid().v4();
  final String? title;
  final String? toolTip;
  final bool isEnabled;
  final bool isSeparatorItem;

  static final MenuItem separator = MenuItem(isSeparatorItem: true);

  MenuItem({
    String? identifier,
    this.title,
    this.toolTip,
    this.isEnabled = true,
    this.isSeparatorItem = false,
  }) {
    if (identifier != null) this.identifier = identifier;
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'title': title ?? '',
      'toolTip': toolTip,
      'isEnabled': isEnabled,
      'isSeparatorItem': isSeparatorItem,
    }..removeWhere((key, value) => value == null);
  }
}
