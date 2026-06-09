import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/document.dart';
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

    int limitDays = 30; // 1 month (Default)
    if (doc.documentType == 'Visa') {
      limitDays = 240; // 8 months
    } else if (doc.documentType == 'Passport') {
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

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Passport':
        return Icons.import_contacts;
      case 'Visa':
        return Icons.card_membership;
      case 'ID':
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

                return Card(
                  elevation: securityInfo['isUrgent'] ? 3 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: securityInfo['isUrgent']
                        ? BorderSide(color: securityInfo['color'], width: 1.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (securityInfo['color'] as Color)
                          .withOpacity(0.1),
                      child: Icon(
                        _getIconForType(doc.documentType),
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
                          'Type: ${doc.documentType}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (doc.notes != null && doc.notes!.isNotEmpty)
                          Text(
                            'Notes: ${doc.notes}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(height: 4),
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
                        ? const Icon(
                            Icons.lock,
                            color: Colors.blueGrey,
                            size: 20,
                          )
                        : const Icon(
                            Icons.no_photography_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                    onTap: () {
                      // TODO: Decript and view
                    },
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
