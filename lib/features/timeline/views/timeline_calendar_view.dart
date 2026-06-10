import 'package:flutter/material.dart';
import 'package:nexus/core/models/timeline_event.dart';
import 'package:nexus/core/utils/timeline_engine.dart';
import 'package:nexus/core/utils/payment_engine.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/payment_ui_helpers.dart';
import 'package:nexus/features/recurring_payments/add_payment_sheet.dart';

class TimelineCalendarView extends StatefulWidget {
  const TimelineCalendarView({super.key});

  @override
  State<TimelineCalendarView> createState() => _TimelineCalendarViewState();
}

class _TimelineCalendarViewState extends State<TimelineCalendarView> {
  late Future<List<TimelineEvent>> _eventsFuture;

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

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

  Map<DateTime, List<TimelineEvent>> _groupEventsByDate(
    List<TimelineEvent> all,
  ) {
    final Map<DateTime, List<TimelineEvent>> grouped = {};
    for (var event in all) {
      final normalizedDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      if (!grouped.containsKey(normalizedDate)) {
        grouped[normalizedDate] = [];
      }
      grouped[normalizedDate]!.add(event);
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
    return FutureBuilder<List<TimelineEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEvents = snapshot.data ?? [];
        final groupedEvents = _groupEventsByDate(allEvents);
        final selectedDayEvents = groupedEvents[_selectedDate] ?? [];

        return Column(
          children: [
            _buildCalendarHeader(),
            _buildDaysOfWeek(),
            _buildCalendarGrid(groupedEvents),
            const Divider(height: 1),
            Expanded(child: _buildSelectedDateEvents(selectedDayEvents)),
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
        children: days
            .map(
              (day) => SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<TimelineEvent>> groupedEvents) {
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
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          if (index < emptyCellsPrefix) return const SizedBox.shrink();

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

          final hasEvents = groupedEvents.containsKey(cellDate);
          final hasUrgent =
              hasEvents && groupedEvents[cellDate]!.any((e) => e.isUrgent);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = cellDate),
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
                  if (hasEvents) ...[
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

  Widget _buildSelectedDateEvents(List<TimelineEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events scheduled for this date.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventCard(context, events[index]),
    );
  }

  Widget _buildEventCard(BuildContext context, TimelineEvent event) {
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
        margin: const EdgeInsets.only(bottom: 12),
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
                  if (event.eventType == 'Payment') ...[
                    const SizedBox(height: 8),
                    (event.originalItem as Payment).isAutoPay
                        ? const Icon(
                            Icons.autorenew,
                            color: Colors.grey,
                            size: 20,
                          )
                        : InkWell(
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
