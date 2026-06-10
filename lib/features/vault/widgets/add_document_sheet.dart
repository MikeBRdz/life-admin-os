import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/document.dart';
import 'package:nexus/core/models/category.dart';
import 'package:nexus/core/services/file_encryption_service.dart';

class AddDocumentSheet extends StatefulWidget {
  final VoidCallback onDocumentAdded;
  final Document? documentToEdit;

  const AddDocumentSheet({
    super.key,
    required this.onDocumentAdded,
    this.documentToEdit,
  });

  @override
  State<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<AddDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _expirationDate;
  File? _selectedFile;
  bool _isSaving = false;
  String? _existingEncryptedPath;

  List<Category> _documentCategories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.documentToEdit != null) {
      final d = widget.documentToEdit!;
      _titleController.text = d.title;
      if (d.notes != null) _notesController.text = d.notes!;
      _expirationDate = d.expirationDate;
      _existingEncryptedPath = d.encryptedFilePath;
    }
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategoriesByModule(
      'document',
    );
    setState(() {
      _documentCategories = categories;
      _isLoadingCategories = false;

      if (widget.documentToEdit != null) {
        _selectedCategoryId = widget.documentToEdit!.categoryId;
      } else if (categories.isNotEmpty) {
        _selectedCategoryId = categories.first.id;
      }
    });
  }

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
      initialDate:
          _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null)
      return;

    setState(() => _isSaving = true);

    try {
      String? finalEncryptedPath = _existingEncryptedPath;

      if (_selectedFile != null) {
        finalEncryptedPath = await FileEncryptionService.encryptAndSaveFile(
          _selectedFile!,
        );
      }

      final doc = Document(
        id: widget.documentToEdit?.id,
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId!,
        encryptedFilePath: finalEncryptedPath,
        expirationDate: _expirationDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.documentToEdit != null) {
        await DatabaseHelper.instance.updateDocument(doc);
      } else {
        await DatabaseHelper.instance.insertDocument(doc);
      }

      widget.onDocumentAdded();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                widget.documentToEdit != null
                    ? 'Edit Secure File'
                    : 'Secure New File',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'File Title (e.g. My US Visa)',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),

              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'File Type'),
                      items: _documentCategories
                          .map(
                            (cat) => DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(cat.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
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

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedFile != null
                      ? 'New File Selected ✓'
                      : (_existingEncryptedPath != null
                            ? 'File already encrypted ✓'
                            : 'No Attached File'),
                ),
                subtitle: Text(
                  _selectedFile != null
                      ? 'Ready to be encrypted with AES-256'
                      : (_existingEncryptedPath != null
                            ? 'Tap to replace existing file'
                            : 'Optional: Add image/PDF to encrypt'),
                  style: TextStyle(
                    color:
                        (_selectedFile != null ||
                            _existingEncryptedPath != null)
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                trailing: Icon(
                  (_selectedFile != null || _existingEncryptedPath != null)
                      ? Icons.gpp_good
                      : Icons.attach_file,
                  color:
                      (_selectedFile != null || _existingEncryptedPath != null)
                      ? Colors.green
                      : null,
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
                    : Text(
                        widget.documentToEdit != null
                            ? 'Update Data'
                            : 'Secure & Save Data',
                      ),
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
