import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../storage/local_storage.dart';

class ExpenseRepository {
  static const _uuid = Uuid();

  ValueListenable<Box<Map>> get listenable =>
      LocalStorage.expensesBox.listenable();

  List<Expense> getAll() {
    final list = LocalStorage.expensesBox.values.map(Expense.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Expense> create({
    required String category,
    required String title,
    required double amount,
    required String note,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      category: category,
      title: title,
      amount: amount,
      note: note,
      createdAt: DateTime.now(),
    );

    await LocalStorage.expensesBox.put(expense.id, expense.toMap());
    return expense;
  }

  Future<void> delete(String id) async {
    await LocalStorage.expensesBox.delete(id);
  }
}
