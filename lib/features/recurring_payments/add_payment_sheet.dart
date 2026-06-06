import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/icon_registry.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddPaymentSheet extends StatefulWidget {
  final Payment? paymentToEdit;

  const AddPaymentSheet({super.key, this.paymentToEdit});

  @override
  State<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<AddPaymentSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Monthly';
  bool _isUrgent = false;

  final List<String> _frequencies = [
    'Daily',
    'Weekly',
    'Biweekly',
    'Monthly',
    'Yearly',
  ];

  late String _selectedIconKey = appIcons.keys.first;

  @override
  void initState() {
    super.initState();

    if (widget.paymentToEdit != null) {
      final p = widget.paymentToEdit!;

      _titleController.text = p.title;
      _amountController.text = p.amount.toString();
      _selectedDate = p.nextPaymentDate;
      _selectedFrequency = p.frequency;
      _isUrgent = p.isUrgent;
      _selectedIconKey = p.iconKey;
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePayment() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the main fields')),
      );
      return;
    }

    final payment = Payment(
      id: widget.paymentToEdit?.id,
      title: _titleController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      nextPaymentDate: _selectedDate,
      frequency: _selectedFrequency,
      isUrgent: _isUrgent,
      iconKey: _selectedIconKey,
    );

    if (widget.paymentToEdit != null) {
      await DatabaseHelper.instance.updatePayment(payment);
    } else {
      await DatabaseHelper.instance.insertPayment(payment);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: bottomInset + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.paymentToEdit != null ? 'Edit Expense' : 'New Expense',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: appIcons.length,
              itemBuilder: (context, index) {
                String key = appIcons.keys.elementAt(index);
                final isSelected = _selectedIconKey == key;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIconKey = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: buildAppIcon(
                      key,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Expense Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount to Pay',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Repeats',
                    border: OutlineInputBorder(),
                  ),
                  items: _frequencies.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFrequency = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Next Payment Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Mark as High Priority'),
            value: _isUrgent,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _isUrgent = value),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _savePayment,
              child: Text(
                widget.paymentToEdit != null
                    ? 'Update Expense'
                    : 'Save Expense',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
