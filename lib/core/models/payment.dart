class Payment {
  final int? id;
  final String title;
  final double amount;
  final DateTime nextPaymentDate;
  final String frequency;
  final bool isUrgent;
  final String iconKey;

  Payment({
    this.id,
    required this.title,
    required this.amount,
    required this.nextPaymentDate,
    required this.frequency,
    required this.isUrgent,
    required this.iconKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'frequency': frequency,
      'isUrgent': isUrgent ? 1 : 0,
      'iconKey': iconKey,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      nextPaymentDate: DateTime.parse(map['nextPaymentDate']),
      frequency: map['frequency'],
      isUrgent: map['isUrgent'] == 1,
      iconKey: map['iconKey'],
    );
  }
}
