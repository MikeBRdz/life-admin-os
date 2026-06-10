import 'package:flutter/material.dart';
import 'package:nexus/core/models/timeline_event.dart';
import 'package:nexus/core/utils/timeline_engine.dart';
import 'package:nexus/core/utils/payment_engine.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/payment_ui_helpers.dart';
import 'package:nexus/features/recurring_payments/add_payment_sheet.dart';
import 'package:nexus/features/vault/widgets/add_document_sheet.dart'; // Asumiendo que quieres abrirlo desde aquí en el futuro

class TimelineFeedView extends StatefulWidget {
  const TimelineFeedView({super.key});

  @override
  State<TimelineFeedView> createState() => _TimelineFeedViewState();
}

class _TimelineFeedViewState extends State<TimelineFeedView> {
  late Future<List<TimelineEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = TimelineEngine.getUnifiedTimeline();
    });
  }

  Map<String, List<TimelineEvent>> _groupEventsByMonth(
    List<TimelineEvent> all,
  ) {
    final Map<String, List<TimelineEvent>> grouped = {};

    for (var event in all) {
      final monthName = PaymentEngine.getMonthName(event.date.month);
      final year = event.date.year;
      final key = '$monthName $year';

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(event);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TimelineEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEvents = snapshot.data ?? [];

        if (allEvents.isEmpty) {
          return const Center(
            child: Text(
              'No upcoming events or renewals',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final groupedEvents = _groupEventsByMonth(allEvents);
        final sectionKeys = groupedEvents.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          itemCount: sectionKeys.length,
          itemBuilder: (context, sectionIndex) {
            final monthKey = sectionKeys[sectionIndex];
            final eventsInMonth = groupedEvents[monthKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  itemCount: eventsInMonth.length,
                  itemBuilder: (context, itemIndex) {
                    return _buildFeedCard(context, eventsInMonth[itemIndex]);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFeedCard(BuildContext context, TimelineEvent event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );
    final daysLeft = eventDate.difference(today).inDays;
    final dateFormatted =
        '${PaymentEngine.getMonthName(event.date.month)} ${event.date.day}';

    return GestureDetector(
      onTap: () async {
        if (event.eventType == 'Payment') {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) =>
                AddPaymentSheet(paymentToEdit: event.originalItem as Payment),
          );
          if (result == true) _loadEvents();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12, left: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: event.eventType == 'Document'
              ? BorderSide(color: event.color, width: 1)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              event.iconWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
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
                          daysLeft == 0
                              ? 'Today'
                              : (daysLeft < 0
                                    ? (event.eventType == 'Payment' &&
                                              (event.originalItem as Payment)
                                                  .isAutoPay
                                          ? 'Auto-paid ✓'
                                          : 'Overdue')
                                    : dateFormatted),
                          style: TextStyle(
                            color: daysLeft < 0 ? Colors.red : Colors.grey[600],
                            fontSize: 13,
                            fontWeight: daysLeft <= 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (event.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: event.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: event.color.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              event.eventType == 'Document'
                                  ? 'Expiring'
                                  : 'Priority',
                              style: TextStyle(
                                color: event.color,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: event.eventType == 'Payment' ? 16 : 12,
                      color: event.eventType == 'Document' ? Colors.grey : null,
                    ),
                  ),
                  if (event.eventType == 'Payment' &&
                      !(event.originalItem as Payment).isAutoPay) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => PaymentUIHelpers.markAsPaid(
                        context,
                        event.originalItem as Payment,
                        _loadEvents,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                  ] else if (event.eventType == 'Payment' &&
                      (event.originalItem as Payment).isAutoPay) ...[
                    const SizedBox(height: 8),
                    const Icon(Icons.autorenew, color: Colors.grey, size: 20),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
