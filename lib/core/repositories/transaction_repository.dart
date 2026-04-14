import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_transaction.dart';
import '../models/enums.dart';
import '../models/transaction_item.dart';
import '../models/user_session.dart';
import '../storage/local_storage.dart';

class TransactionRepository {
  static const _uuid = Uuid();

  ValueListenable<Box<Map>> get listenable =>
      LocalStorage.transactionsBox.listenable();

  List<AppTransaction> getAll() {
    final list =
        LocalStorage.transactionsBox.values.map(AppTransaction.fromMap).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  AppTransaction? findById(String id) {
    final map = LocalStorage.transactionsBox.get(id);
    if (map == null) return null;
    return AppTransaction.fromMap(map);
  }

  Future<AppTransaction> create({
    required String tableNo,
    required List<TransactionItem> items,
    required double discountPercent,
    required double taxPercent,
    required double servicePercent,
    required PaymentMethod paymentMethod,
    required TransactionStatus status,
    required UserSession cashier,
  }) async {
    final now = DateTime.now();
    final tx = AppTransaction(
      id: _uuid.v4(),
      orderNo: 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}',
      tableNo: tableNo.trim().isEmpty ? '-' : tableNo.trim(),
      cashierName: cashier.name,
      cashierRole: cashier.role,
      items: items,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
      servicePercent: servicePercent,
      paymentMethod: paymentMethod,
      status: status,
      paidAmount: status == TransactionStatus.lunas
          ? items.fold<double>(0, (sum, item) => sum + item.total)
          : 0,
      createdAt: now,
      updatedAt: now,
    );

    final adjusted = tx.copyWith(
      paidAmount: status == TransactionStatus.lunas ? tx.grandTotal : 0,
    );

    await LocalStorage.transactionsBox.put(adjusted.id, adjusted.toMap());
    return adjusted;
  }

  Future<void> updateStatus({
    required String id,
    required TransactionStatus status,
    required double paidAmount,
  }) async {
    final current = findById(id);
    if (current == null) return;

    final next = current.copyWith(
      status: status,
      paidAmount: paidAmount,
      updatedAt: DateTime.now(),
    );

    await LocalStorage.transactionsBox.put(id, next.toMap());
  }

  Future<void> delete(String id) async {
    await LocalStorage.transactionsBox.delete(id);
  }

  List<AppTransaction> forDate(DateTime date) {
    return getAll().where((item) {
      return item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day;
    }).toList();
  }
}
