import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/icon_registry.dart';
import 'package:nexus/features/recurring_payments/add_payment_sheet.dart';

class TimelineFeedView extends StatefulWidget {
  const TimelineFeedView({super.key});

  @override
  State<TimelineFeedView> createState() => _TimelineFeedViewState();
}

class _TimelineFeedViewState extends State<TimelineFeedView> {
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

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Map<String, List<Payment>> _groupPaymentsByMonth(List<Payment> all) {
    all.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));

    final Map<String, List<Payment>> grouped = {};

    for (var payment in all) {
      final monthName = _getMonthName(payment.nextPaymentDate.month);
      final year = payment.nextPaymentDate.year;
      final key = '$monthName $year'; // e.g., "June 2026"

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(payment);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPayments = snapshot.data ?? [];

        if (allPayments.isEmpty) {
          return const Center(
            child: Text(
              'No upcoming payments',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final groupedPayments = _groupPaymentsByMonth(allPayments);
        final sectionKeys = groupedPayments.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          itemCount: sectionKeys.length,
          itemBuilder: (context, sectionIndex) {
            final monthKey = sectionKeys[sectionIndex];
            final paymentsInMonth = groupedPayments[monthKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MONTH HEADER
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    bottom: 12.0,
                    left: 4.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        monthKey,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paymentsInMonth.length,
                  itemBuilder: (context, itemIndex) {
                    final payment = paymentsInMonth[itemIndex];
                    return _buildFeedCard(context, payment);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFeedCard(BuildContext context, Payment payment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final paymentDate = DateTime(
      payment.nextPaymentDate.year,
      payment.nextPaymentDate.month,
      payment.nextPaymentDate.day,
    );
    final daysLeft = paymentDate.difference(today).inDays;

    final dateFormatted =
        '${_getMonthName(payment.nextPaymentDate.month)} ${payment.nextPaymentDate.day}';

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
        margin: const EdgeInsets.only(bottom: 12, left: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              buildAppIcon(
                payment.iconKey,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          // English dynamic labels
                          daysLeft == 0
                              ? 'Today'
                              : (daysLeft < 0 ? 'Overdue' : dateFormatted),
                          style: TextStyle(
                            color: daysLeft <= 0
                                ? Colors.red
                                : Colors.grey[600],
                            fontSize: 13,
                            fontWeight: daysLeft <= 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (payment.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'Priority', // English badge
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Text(
                '\$${payment.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
