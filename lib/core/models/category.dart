class Category {
  final int? id;
  final String name;
  final String module;
  final String? iconCode;
  final String? colorHex;

  Category({
    this.id,
    required this.name,
    required this.module,
    this.iconCode,
    this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'module': module,
      'iconCode': iconCode,
      'colorHex': colorHex,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      module: map['module'] as String,
      iconCode: map['iconCode'] as String?,
      colorHex: map['colorHex'] as String?,
    );
  }
}
