class Payment {
  final int? id;
  final String title;
  final double amount;
  final DateTime nextPaymentDate;
  final String frequency;
  final String iconKey;
  final bool isUrgent;
  final bool isAutoPay;

  Payment({
    this.id,
    required this.title,
    required this.amount,
    required this.nextPaymentDate,
    required this.frequency,
    required this.iconKey,
    required this.isUrgent,
    required this.isAutoPay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'frequency': frequency,
      'iconKey': iconKey,
      'isUrgent': isUrgent ? 1 : 0,
      'isAutoPay': isAutoPay ? 1 : 0,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      nextPaymentDate: DateTime.parse(map['nextPaymentDate']),
      frequency: map['frequency'],
      iconKey: map['iconKey'],
      isUrgent: map['isUrgent'] == 1,
      isAutoPay: map['isAutoPay'] == 1,
    );
  }
}
