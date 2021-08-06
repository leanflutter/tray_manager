class MenuItem {
  final String? tag;
  final String? title;
  final String? toolTip;
  final bool isEnabled;
  final bool isSeparatorItem;

  static final MenuItem separator = MenuItem(isSeparatorItem: true);

  MenuItem({
    this.tag,
    this.title,
    this.toolTip,
    this.isEnabled = true,
    this.isSeparatorItem = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'title': title,
      'toolTip': toolTip,
      'isEnabled': isEnabled,
      'isSeparatorItem': isSeparatorItem,
    }..removeWhere((key, value) => value == null);
  }
}
