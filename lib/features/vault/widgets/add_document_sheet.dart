import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/document.dart';
import 'package:nexus/core/services/file_encryption_service.dart';

class AddDocumentSheet extends StatefulWidget {
  final VoidCallback onDocumentAdded;
  const AddDocumentSheet({super.key, required this.onDocumentAdded});

  @override
  State<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<AddDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'ID';
  DateTime? _expirationDate;
  File? _selectedFile;
  bool _isSaving = false;

  final List<String> _types = ['ID', 'Passport', 'Visa', 'Other'];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? encryptedPath;

      if (_selectedFile != null) {
        encryptedPath = await FileEncryptionService.encryptAndSaveFile(
          _selectedFile!,
        );
      }

      final newDoc = Document(
        title: _titleController.text.trim(),
        documentType: _selectedType,
        encryptedFilePath: encryptedPath,
        expirationDate: _expirationDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await DatabaseHelper.instance.insertDocument(newDoc);
      widget.onDocumentAdded();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Encryption Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: mediaQuery.viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Secure New Document',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title (e.g. My US Visa)',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Document Type'),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Folio / Passport No. / Notes (Optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Date Selector (Optional)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _expirationDate == null
                      ? 'No Expiration Date'
                      : 'Expires: ${_expirationDate!.toLocal().toString().split(' ')[0]}',
                ),
                subtitle: const Text('Tap to set visibility alert trigger'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const Divider(),

              // File Selector (Optional)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedFile == null
                      ? 'No Attached File'
                      : 'File Selected ✓',
                ),
                subtitle: Text(
                  _selectedFile == null
                      ? 'Optional: Add image/PDF to encrypt'
                      : 'Ready to be encrypted with AES-256',
                  style: TextStyle(
                    color: _selectedFile == null ? Colors.grey : Colors.green,
                  ),
                ),
                trailing: Icon(
                  _selectedFile == null ? Icons.attach_file : Icons.gpp_good,
                  color: _selectedFile == null ? null : Colors.green,
                ),
                onTap: _pickFile,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Secure & Save Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
