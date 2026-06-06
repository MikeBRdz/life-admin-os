import 'package:flutter/material.dart';
import 'package:nexus/features/timeline/timeline_view_type.dart';
import 'package:nexus/features/timeline/views/timeline_board_view.dart';
import 'package:nexus/features/timeline/views/timeline_feed_view.dart';
import 'package:nexus/features/timeline/views/timeline_calendar_view.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  TimelineViewType _currentView = TimelineViewType.board;

  Widget _buildCurrentView() {
    switch (_currentView) {
      case TimelineViewType.board:
        return const TimelineBoardView();
      case TimelineViewType.feed:
        return const TimelineFeedView();
      case TimelineViewType.calendar:
        return const TimelineCalendarView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timeline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SegmentedButton<TimelineViewType>(
                segments: const [
                  ButtonSegment(
                    value: TimelineViewType.board,
                    icon: Icon(Icons.dashboard_outlined),
                  ),
                  ButtonSegment(
                    value: TimelineViewType.feed,
                    icon: Icon(Icons.view_agenda_outlined),
                  ),
                  ButtonSegment(
                    value: TimelineViewType.calendar,
                    icon: Icon(Icons.calendar_month_outlined),
                  ),
                ],
                selected: {_currentView},
                onSelectionChanged: (Set<TimelineViewType> newSelection) {
                  setState(() {
                    _currentView = newSelection.first;
                  });
                },
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentView(),
      ),
    );
  }
}
