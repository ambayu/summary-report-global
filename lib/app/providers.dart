import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repositories/auth_repository.dart';
import '../core/repositories/customer_repository.dart';
import '../core/repositories/expense_repository.dart';
import '../core/repositories/product_repository.dart';
import '../core/repositories/settings_repository.dart';
import '../core/repositories/transaction_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});
