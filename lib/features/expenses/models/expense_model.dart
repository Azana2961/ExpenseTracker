class ExpenseModel {
  final String id;
  final DateTime date;
  final String label;
  final double amount;
  final String category;
  final bool isCleared;
  final double amountPaid; // How much has been repaid so far (Borrow/Loan only)

  ExpenseModel({
    required this.id,
    required this.date,
    required this.label,
    required this.amount,
    required this.category,
    this.isCleared = true, // Defaults to true unless it is a Pending Loan/Borrow
    this.amountPaid = 0,
  });

  /// How much is still owed / outstanding
  double get remainingAmount => (amount - amountPaid).clamp(0.0, double.infinity);

  /// True if this is a Borrow or Loan entry with partial or no payment
  bool get isPartiallyPaid => amountPaid > 0 && amountPaid < amount;

  // Convert our Dart Object into a Map that SQLite can understand
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(), // SQLite needs dates as text strings
      'label': label,
      'amount': amount,
      'category': category,
      'isCleared': isCleared ? 1 : 0, // SQLite uses 1 for true, 0 for false
      'amountPaid': amountPaid,
    };
  }

  // Convert the Map from SQLite back into a Dart Object for the UI
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      label: map['label'],
      amount: map['amount'],
      category: map['category'],
      isCleared: map['isCleared'] == 1,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0,
    );
  }

  // A handy method to easily update specific fields (like marking a loan as cleared)
  ExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? label,
    double? amount,
    String? category,
    bool? isCleared,
    double? amountPaid,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isCleared: isCleared ?? this.isCleared,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }
}