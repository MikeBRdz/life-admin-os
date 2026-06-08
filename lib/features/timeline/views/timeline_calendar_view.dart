import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/icon_registry.dart';
import 'package:nexus/features/recurring_payments/add_payment_sheet.dart';
import 'package:nexus/core/utils/payment_engine.dart';
import 'package:nexus/core/utils/payment_ui_helpers.dart';

class TimelineCalendarView extends StatefulWidget {
  const TimelineCalendarView({super.key});

  @override
  State<TimelineCalendarView> createState() => _TimelineCalendarViewState();
}

class _TimelineCalendarViewState extends State<TimelineCalendarView> {
  late Future<List<Payment>> _paymentsFuture;

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

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

  Map<DateTime, List<Payment>> _groupPaymentsByDate(List<Payment> all) {
    final Map<DateTime, List<Payment>> grouped = {};
    for (var payment in all) {
      final normalizedDate = DateTime(
        payment.nextPaymentDate.year,
        payment.nextPaymentDate.month,
        payment.nextPaymentDate.day,
      );

      if (!grouped.containsKey(normalizedDate)) {
        grouped[normalizedDate] = [];
      }
      grouped[normalizedDate]!.add(payment);
    }
    return grouped;
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
        1,
      );
    });
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
        final projectedPayments = PaymentEngine.generateProjectedTimeline(
          allPayments,
        );
        final groupedPayments = _groupPaymentsByDate(projectedPayments);

        final selectedDayPayments = groupedPayments[_selectedDate] ?? [];

        return Column(
          children: [
            _buildCalendarHeader(),
            _buildDaysOfWeek(),
            _buildCalendarGrid(groupedPayments),

            const Divider(height: 1),

            Expanded(child: _buildSelectedDatePayments(selectedDayPayments)),
          ],
        );
      },
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${PaymentEngine.getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          return SizedBox(
            width: 40,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<Payment>> groupedPayments) {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    final firstDayWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;
    final emptyCellsPrefix = firstDayWeekday == 7 ? 0 : firstDayWeekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daysInMonth + emptyCellsPrefix,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, // 7 days a week
          childAspectRatio: 1.0, // Perfect squares
        ),
        itemBuilder: (context, index) {
          if (index < emptyCellsPrefix) {
            return const SizedBox.shrink();
          }

          final dayNumber = index - emptyCellsPrefix + 1;
          final cellDate = DateTime(
            _focusedMonth.year,
            _focusedMonth.month,
            dayNumber,
          );
          final isSelected = cellDate == _selectedDate;
          final isToday =
              cellDate ==
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              );

          final hasPayments = groupedPayments.containsKey(cellDate);
          final hasUrgent =
              hasPayments && groupedPayments[cellDate]!.any((p) => p.isUrgent);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = cellDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isToday
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (hasPayments) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hasUrgent
                            ? Colors.red
                            : (isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDatePayments(List<Payment> payments) {
    if (payments.isEmpty) {
      return const Center(
        child: Text(
          'No payments scheduled for this date.',
          style: TextStyle(color: Colors.grey),
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
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
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
        margin: const EdgeInsets.only(bottom: 12),
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
                          'Priority',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

              const SizedBox(width: 8),
              payment.isAutoPay
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.autorenew,
                        color: Colors.grey,
                        size: 24,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 28,
                      ),
                      onPressed: () => PaymentUIHelpers.markAsPaid(
                        context,
                        payment,
                        _loadPayments,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
