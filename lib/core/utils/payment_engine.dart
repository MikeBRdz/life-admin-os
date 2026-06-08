import 'package:nexus/core/models/payment.dart';

class PaymentEngine {
  static DateTime _getNextDate(DateTime current, String frequency) {
    if (frequency == 'Monthly') {
      return DateTime(current.year, current.month + 1, current.day);
    } else if (frequency == 'Weekly') {
      return current.add(const Duration(days: 7));
    } else if (frequency == 'Annually') {
      return DateTime(current.year + 1, current.month, current.day);
    }
    return current; // Fallback
  }

  static List<Payment> generateProjectedTimeline(List<Payment> dbPayments) {
    final List<Payment> projectedTimeline = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime oneYearFromNow = DateTime(
      now.year + 1,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    for (var payment in dbPayments) {
      if (payment.isAutoPay) {
        DateTime projectionDate = payment.nextPaymentDate;

        while (projectionDate.isBefore(today)) {
          DateTime nextPeriod = _getNextDate(projectionDate, payment.frequency);

          if (nextPeriod.isBefore(today) ||
              nextPeriod.isAtSameMomentAs(today)) {
            projectionDate = nextPeriod;
          } else {
            break;
          }
        }

        do {
          projectedTimeline.add(
            Payment(
              id: payment.id,
              title: payment.title,
              amount: payment.amount,
              nextPaymentDate: projectionDate,
              frequency: payment.frequency,
              iconKey: payment.iconKey,
              isAutoPay: payment.isAutoPay,
              isUrgent: payment.isUrgent,
            ),
          );

          projectionDate = _getNextDate(projectionDate, payment.frequency);
        } while (projectionDate.isBefore(oneYearFromNow));
      } else {
        projectedTimeline.add(payment);
      }
    }

    return projectedTimeline;
  }

  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static Payment advancePaymentPeriod(Payment oldPayment) {
    DateTime newDate = oldPayment.nextPaymentDate;

    if (oldPayment.frequency == 'Monthly') {
      newDate = DateTime(newDate.year, newDate.month + 1, newDate.day);
    } else if (oldPayment.frequency == 'Weekly') {
      newDate = newDate.add(const Duration(days: 7));
    } else if (oldPayment.frequency == 'Annually') {
      newDate = DateTime(newDate.year + 1, newDate.month, newDate.day);
    }

    return Payment(
      id: oldPayment.id,
      title: oldPayment.title,
      amount: oldPayment.amount,
      nextPaymentDate: _getNextDate(
        oldPayment.nextPaymentDate,
        oldPayment.frequency,
      ),
      frequency: oldPayment.frequency,
      iconKey: oldPayment.iconKey,
      isAutoPay: oldPayment.isAutoPay,
      isUrgent: oldPayment.isUrgent,
    );
  }
}
