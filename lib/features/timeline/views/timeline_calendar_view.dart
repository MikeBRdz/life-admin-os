import 'package:flutter/material.dart';

class TimelineCalendarView extends StatelessWidget {
  const TimelineCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Vista de Calendario',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
