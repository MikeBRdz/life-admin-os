import 'package:flutter/material.dart';

class TimelineEvent {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final Widget iconWidget;
  final Color color;
  final bool isUrgent;
  final String eventType;
  final dynamic originalItem;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.iconWidget,
    required this.color,
    required this.isUrgent,
    required this.eventType,
    required this.originalItem,
  });
}
