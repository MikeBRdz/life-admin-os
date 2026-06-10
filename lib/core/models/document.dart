class Document {
  final int? id;
  final String title;
  final int categoryId;
  final String? categoryName;
  final String? encryptedFilePath;
  final DateTime? expirationDate;
  final String? notes;

  Document({
    this.id,
    required this.title,
    required this.categoryId,
    this.categoryName,
    this.encryptedFilePath,
    this.expirationDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'categoryId': categoryId,
      'encryptedFilePath': encryptedFilePath,
      'expirationDate': expirationDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      title: map['title'] as String,
      categoryId: map['categoryId'] as int,
      categoryName: map.containsKey('categoryName')
          ? map['categoryName'] as String
          : null,
      encryptedFilePath: map['encryptedFilePath'] as String?,
      expirationDate: map['expirationDate'] != null
          ? DateTime.parse(map['expirationDate'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }
}
