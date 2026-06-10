import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/timeline_event.dart';
import 'package:nexus/core/utils/payment_engine.dart';
import 'package:nexus/core/utils/icon_registry.dart';

class TimelineEngine {
  static Future<List<TimelineEvent>> getUnifiedTimeline() async {
    final List<TimelineEvent> unifiedEvents = [];
    final dbHelper = DatabaseHelper.instance;

    final rawPayments = await dbHelper.getPayments();
    final projectedPayments = PaymentEngine.generateProjectedTimeline(
      rawPayments,
    );

    for (var payment in projectedPayments) {
      final color = payment.isUrgent ? Colors.red : Colors.blue;

      unifiedEvents.add(
        TimelineEvent(
          id: 'payment_${payment.id}_${payment.nextPaymentDate.millisecondsSinceEpoch}',
          title: payment.title,
          subtitle: '\$${payment.amount.toStringAsFixed(2)}',
          date: payment.nextPaymentDate,
          iconWidget: buildAppIcon(payment.iconKey, color: color, size: 20),
          color: color,
          isUrgent: payment.isUrgent,
          eventType: 'Payment',
          originalItem: payment,
        ),
      );
    }

    final rawDocuments = await dbHelper.getDocuments();
    for (var doc in rawDocuments) {
      if (doc.expirationDate != null) {
        final daysLeft = doc.expirationDate!.difference(DateTime.now()).inDays;
        final bool urgent = daysLeft <= 30;
        final color = urgent ? Colors.orange : Colors.teal;

        unifiedEvents.add(
          TimelineEvent(
            id: 'doc_${doc.id}',
            title: 'Renew: ${doc.title}',
            subtitle: 'Doc: ${doc.categoryName ?? 'Unknown'}',
            date: doc.expirationDate!,
            iconWidget: Icon(
              Icons.assignment_late_outlined,
              color: color,
              size: 20,
            ),
            color: color,
            isUrgent: urgent,
            eventType: 'Document',
            originalItem: doc,
          ),
        );
      }
    }

    unifiedEvents.sort((a, b) => a.date.compareTo(b.date));

    return unifiedEvents;
  }
}
