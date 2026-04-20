import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';

class LocalStorage {
  static const _uuid = Uuid();

  static late Box<Map> sessionBox;
  static late Box<Map> usersBox;
  static late Box<Map> productsBox;
  static late Box<Map> customersBox;
  static late Box<Map> transactionsBox;
  static late Box<Map> expensesBox;
  static late Box<Map> settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    sessionBox = await Hive.openBox<Map>('session');
    usersBox = await Hive.openBox<Map>('users');
    productsBox = await Hive.openBox<Map>('products');
    customersBox = await Hive.openBox<Map>('customers');
    transactionsBox = await Hive.openBox<Map>('transactions');
    expensesBox = await Hive.openBox<Map>('expenses');
    settingsBox = await Hive.openBox<Map>('settings');

    await _seedData();
  }

  static bool get hasSession => sessionBox.get('current') != null;

  static Future<void> _seedData() async {
    if (usersBox.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final users = [
        {
          'id': _uuid.v4(),
          'username': 'owner',
          'password': '123456',
          'role': 'owner',
          'createdAt': now,
          'updatedAt': now,
        },
        {
          'id': _uuid.v4(),
          'username': 'admin',
          'password': '123456',
          'role': 'admin',
          'createdAt': now,
          'updatedAt': now,
        },
        {
          'id': _uuid.v4(),
          'username': 'kasir',
          'password': '123456',
          'role': 'kasir',
          'createdAt': now,
          'updatedAt': now,
        },
      ];

      for (final user in users) {
        await usersBox.put(user['username'] as String, user);
      }
    }

    if (settingsBox.get('default') == null) {
      final defaultRoles = AppSettings.defaultRoles();
      await settingsBox.put('default', {
        'cafeName': 'Summary Cafe',
        'logoBase64': null,
        'taxPercent': 10,
        'activePayments': [
          'cash',
          'qris',
          'debitKredit',
          'ewallet',
          'transfer',
        ],
        'roles': defaultRoles.map((role) => role.toMap()).toList(),
      });
    }

    if (productsBox.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final data = [
        {
          'id': _uuid.v4(),
          'name': 'Americano',
          'category': 'Coffee',
          'sellPrice': 22000,
          'costPrice': 9000,
          'available': true,
          'stock': 40,
          'createdAt': now,
          'updatedAt': now,
        },
        {
          'id': _uuid.v4(),
          'name': 'Cappuccino',
          'category': 'Coffee',
          'sellPrice': 28000,
          'costPrice': 12000,
          'available': true,
          'stock': 35,
          'createdAt': now,
          'updatedAt': now,
        },
        {
          'id': _uuid.v4(),
          'name': 'Croissant Butter',
          'category': 'Pastry',
          'sellPrice': 18000,
          'costPrice': 8000,
          'available': true,
          'stock': 25,
          'createdAt': now,
          'updatedAt': now,
        },
      ];

      for (final item in data) {
        await productsBox.put(item['id'] as String, item);
      }
    }

    if (customersBox.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await customersBox.put(_uuid.v4(), {
        'id': _uuid.v4(),
        'name': 'Pelanggan Umum',
        'phone': '-',
        'totalPurchase': 0,
        'points': 0,
        'isFavorite': false,
        'createdAt': now,
      });
    }
  }
}
