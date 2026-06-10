import 'package:flutter/material.dart';
import 'package:nexus/core/models/timeline_event.dart';
import 'package:nexus/core/utils/timeline_engine.dart';
import 'package:nexus/core/utils/payment_engine.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/payment_ui_helpers.dart';
import 'package:nexus/features/recurring_payments/add_payment_sheet.dart';

class TimelineBoardView extends StatefulWidget {
  const TimelineBoardView({super.key});

  @override
  State<TimelineBoardView> createState() => _TimelineBoardViewState();
}

class _TimelineBoardViewState extends State<TimelineBoardView> {
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

  List<TimelineEvent> _filterEventsByRange(
    List<TimelineEvent> all,
    int startDays,
    int endDays,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((event) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      final difference = eventDate.difference(today).inDays;
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

    return FutureBuilder<List<TimelineEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEvents = snapshot.data ?? [];

        final thisWeek = _filterEventsByRange(allEvents, 0, 7);
        final thisMonth = _filterEventsByRange(allEvents, 8, 30);
        final next = _filterEventsByRange(allEvents, 31, -1);

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
    List<TimelineEvent> events,
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
                    '${events.length}',
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
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'No pending items',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return _buildKanbanCard(context, events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(BuildContext context, TimelineEvent event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );
    final daysLeft = eventDate.difference(today).inDays;

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
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: event.eventType == 'Document'
              ? BorderSide(color: event.color, width: 1)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              event.iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
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
                              ? 'Today'
                              : (daysLeft < 0
                                    ? 'Overdue'
                                    : 'In $daysLeft days'),
                          style: TextStyle(
                            color: daysLeft <= 0
                                ? Colors.red
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (event.isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: event.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: event.color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              event.eventType == 'Document'
                                  ? 'Expiring'
                                  : 'Priority',
                              style: TextStyle(
                                color: event.color,
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
                event.subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: event.eventType == 'Payment' ? 14 : 10,
                  color: event.eventType == 'Document' ? Colors.grey : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
