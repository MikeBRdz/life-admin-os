import 'package:flutter/material.dart';

class TimelineFeedView extends StatelessWidget {
  const TimelineFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_agenda_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Vista de Feed',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}