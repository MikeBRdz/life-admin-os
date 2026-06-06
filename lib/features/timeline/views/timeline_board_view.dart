import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/icon_registry.dart';
import 'package:nexus/features/recurring_payments/add_payment_sheet.dart';

class TimelineBoardView extends StatefulWidget {
  const TimelineBoardView({super.key});

  @override
  State<TimelineBoardView> createState() => _TimelineBoardViewState();
}

class _TimelineBoardViewState extends State<TimelineBoardView> {
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

  List<Payment> _filterPaymentsByRange(
    List<Payment> all,
    int startDays,
    int endDays,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((payment) {
      final paymentDate = DateTime(
        payment.nextPaymentDate.year,
        payment.nextPaymentDate.month,
        payment.nextPaymentDate.day,
      );
      final difference = paymentDate.difference(today).inDays;
      if (endDays == -1) {
        return difference >= startDays;
      }

      return difference >= startDays && difference <= endDays;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth * 0.85;

    return FutureBuilder<List<Payment>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        final allPayments = snapshot.data ?? [];

        final thisWeek = _filterPaymentsByRange(allPayments, 0, 7);
        final thisMonth = _filterPaymentsByRange(allPayments, 8, 30);
        final next = _filterPaymentsByRange(allPayments, 31, -1);

        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildKanbanColumn('This Week', thisWeek, columnWidth),
            _buildKanbanColumn('This Month', thisMonth, columnWidth),
            _buildKanbanColumn('Next', next, columnWidth),
          ],
        );
      },
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<Payment> payments,
    double width,
  ) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${payments.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: payments.isEmpty
                ? const Center(
                    child: Text(
                      'No pending items',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return _buildKanbanCard(context, payment);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(BuildContext context, Payment payment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final paymentDate = DateTime(
      payment.nextPaymentDate.year,
      payment.nextPaymentDate.month,
      payment.nextPaymentDate.day,
    );
    final daysLeft = paymentDate.difference(today).inDays;

    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => AddPaymentSheet(paymentToEdit: payment),
        );

        if (result == true) {
          _loadPayments();
        }
      },
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              buildAppIcon(
                payment.iconKey,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Text(
                          daysLeft == 0
                              ? 'Pay today'
                              : (daysLeft < 0
                                    ? 'Overdue'
                                    : 'In $daysLeft days'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (payment.isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Priority',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '\$${payment.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
