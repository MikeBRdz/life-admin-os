import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/icon_registry.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'add_payment_sheet.dart';

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() =>
      _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen> {
  late Future<List<Payment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  void _loadPayments() {
    setState(() {
      _paymentsFuture = DatabaseHelper.instance.getPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Payment>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar datos: ${snapshot.error}'),
            );
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return const Center(
              child: Text(
                'No hay gastos registrados.\nToca el botón + para empezar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(context, payment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const AddPaymentSheet(),
          );

          if (result == true) {
            _loadPayments();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final dateFormatted =
        '${payment.nextPaymentDate.day}/${payment.nextPaymentDate.month}/${payment.nextPaymentDate.year}';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: payment.isUrgent
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: buildAppIcon(
                payment.iconKey,
                color: payment.isUrgent
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateFormatted • ${payment.frequency}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              '\$${payment.amount.toStringAsFixed(2)}', // Asegura 2 decimales
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
