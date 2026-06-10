import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/document.dart';
import 'package:nexus/core/services/file_encryption_service.dart';
import 'package:nexus/features/vault/widgets/add_document_sheet.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<Document> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await DatabaseHelper.instance.getDocuments();
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _previewDocument(Document doc) async {
    if (doc.encryptedFilePath == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final File decryptedFile = await FileEncryptionService.decryptFile(
        doc.encryptedFilePath!,
      );
      if (mounted) Navigator.pop(context);

      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Image.file(decryptedFile, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error decrypting: $e')));
    }
  }

  Map<String, dynamic> _checkExpirationStatus(Document doc) {
    if (doc.expirationDate == null) {
      return {
        'status': 'No Expirable',
        'color': Colors.grey,
        'isUrgent': false,
      };
    }

    final now = DateTime.now();
    final difference = doc.expirationDate!.difference(now).inDays;

    if (difference < 0) {
      return {'status': 'EXPIRED ❌', 'color': Colors.red, 'isUrgent': true};
    }

    int limitDays = 30; // 1 month
    if (doc.categoryId == 2) {
      limitDays = 240; // 8 months
    } else if (doc.categoryId == 1) {
      limitDays = 180; // 6 months
    }

    if (difference <= limitDays) {
      final months = (difference / 30).toStringAsFixed(1);
      return {
        'status': 'Renew Soon (~$months months left) ⚠️',
        'color': Colors.orange[800],
        'isUrgent': true,
      };
    }

    final monthsLeft = (difference / 30).toStringAsFixed(1);
    return {
      'status': '$monthsLeft months validity',
      'color': Colors.green,
      'isUrgent': false,
    };
  }

  IconData _getIconForType(int categoryId) {
    switch (categoryId) {
      case 1:
        return Icons.import_contacts;
      case 2:
        return Icons.card_membership;
      case 3:
        return Icons.badge_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? const Center(
              child: Text(
                'No documents secured yet.\nTap + to register your first record.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                final securityInfo = _checkExpirationStatus(doc);

                final exactDateStr = doc.expirationDate != null
                    ? '${doc.expirationDate!.day.toString().padLeft(2, '0')}/${doc.expirationDate!.month.toString().padLeft(2, '0')}/${doc.expirationDate!.year}'
                    : 'N/A';

                return Dismissible(
                  key: ValueKey(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete secure file?'),
                        content: const Text(
                          'This will permanently delete the record and the encrypted file from your device. This cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    if (doc.id != null) {
                      await DatabaseHelper.instance.deleteDocument(doc.id!);
                      _loadDocuments();
                    }
                  },
                  child: Card(
                    elevation: securityInfo['isUrgent'] ? 3 : 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: securityInfo['isUrgent']
                          ? BorderSide(color: securityInfo['color'], width: 1.5)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: (securityInfo['color'] as Color)
                            .withOpacity(0.1),
                        child: Icon(
                          _getIconForType(doc.categoryId),
                          color: securityInfo['color'],
                        ),
                      ),
                      title: Text(
                        doc.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type: ${doc.categoryName ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (doc.notes != null && doc.notes!.isNotEmpty)
                            Text(
                              'Notes: ${doc.notes}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),

                          const SizedBox(height: 6),

                          if (doc.expirationDate != null)
                            Text(
                              'Exp: $exactDateStr',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                          Text(
                            securityInfo['status'],
                            style: TextStyle(
                              color: securityInfo['color'],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      trailing: doc.encryptedFilePath != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_red_eye,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () => _previewDocument(doc),
                            )
                          : const Icon(
                              Icons.no_photography_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),

                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => AddDocumentSheet(
                            documentToEdit: doc,
                            onDocumentAdded: _loadDocuments,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) =>
                AddDocumentSheet(onDocumentAdded: _loadDocuments),
          );
        },
        child: const Icon(Icons.add_moderator),
      ),
    );
  }
}
