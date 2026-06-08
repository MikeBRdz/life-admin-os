import 'package:flutter/material.dart';
import 'package:nexus/core/db/database_helper.dart';
import 'package:nexus/core/models/payment.dart';
import 'package:nexus/core/utils/payment_engine.dart';

class PaymentUIHelpers {
  static void markAsPaid(
    BuildContext context,
    Payment payment,
    VoidCallback onUpdate,
  ) async {
    final updatedPayment = PaymentEngine.advancePaymentPeriod(payment);
    await DatabaseHelper.instance.updatePayment(updatedPayment);
    onUpdate();

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment moved to next period.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await DatabaseHelper.instance.updatePayment(payment);
              onUpdate();
            },
          ),
        ),
      );
    }
  }
}
