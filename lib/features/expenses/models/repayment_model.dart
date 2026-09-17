import 'dart:math';

/// A single repayment event, always linked to a parent Loan or Borrow record.
///
/// Borrow repayment  → cash LEFT your pocket on [date]    → adds to daily spent
/// Loan  repayment   → cash ENTERED your pocket on [date] → reduces daily spent
class RepaymentModel {
  final String id;
  final String parentId;  // FK → ExpenseModel.id
  final String category;  // 'Loan' or 'Borrow' (denormalized for easy queries)
  final double amount;
  final DateTime date;    // The day the cash physically moved

  const RepaymentModel({
    required this.id,
    required this.parentId,
    required this.category,
    required this.amount,
    required this.date,
  });

  /// Convenience factory: generates a unique ID automatically.
  factory RepaymentModel.create({
    required String parentId,
    required String category,
    required double amount,
    required DateTime date,
  }) {
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return RepaymentModel(
      id: 'rp_${date.millisecondsSinceEpoch}_$rand',
      parentId: parentId,
      category: category,
      amount: amount,
      date: date,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'parentId': parentId,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory RepaymentModel.fromMap(Map<String, dynamic> map) => RepaymentModel(
    id: map['id'] as String,
    parentId: map['parentId'] as String,
    category: map['category'] as String,
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date'] as String),
  );
}
