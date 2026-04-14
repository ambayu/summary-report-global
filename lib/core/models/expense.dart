class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.title,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String title;
  final double amount;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'amount': amount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<dynamic, dynamic> map) {
    return Expense(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Lain-lain',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
