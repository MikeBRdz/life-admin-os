class Document {
  final int? id;
  final String title;
  final String documentType;
  final String? encryptedFilePath;
  final DateTime? expirationDate;
  final String? notes;

  Document({
    this.id,
    required this.title,
    required this.documentType,
    this.encryptedFilePath,
    this.expirationDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'documentType': documentType,
      'encryptedFilePath': encryptedFilePath,
      'expirationDate': expirationDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      title: map['title'] as String,
      documentType: map['documentType'] as String,
      encryptedFilePath: map['encryptedFilePath'] as String?,
      expirationDate: map['expirationDate'] != null
          ? DateTime.parse(map['expirationDate'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }
}
