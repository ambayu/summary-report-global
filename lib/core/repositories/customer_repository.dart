import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../storage/local_storage.dart';

class CustomerRepository {
  static const _uuid = Uuid();

  ValueListenable<Box<Map>> get listenable =>
      LocalStorage.customersBox.listenable();

  List<Customer> getAll() {
    final list = LocalStorage.customersBox.values.map(Customer.fromMap).toList()
      ..sort((a, b) => b.totalPurchase.compareTo(a.totalPurchase));
    return list;
  }

  Future<Customer> create({required String name, required String phone}) async {
    final customer = Customer(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone.trim(),
      totalPurchase: 0,
      points: 0,
      isFavorite: false,
      createdAt: DateTime.now(),
    );

    await LocalStorage.customersBox.put(customer.id, customer.toMap());
    return customer;
  }

  Future<void> update({
    required String id,
    required String name,
    required String phone,
  }) async {
    final current = LocalStorage.customersBox.get(id);
    if (current == null) return;

    final customer = Customer.fromMap(current);
    final next = customer.copyWith(name: name.trim(), phone: phone.trim());
    await LocalStorage.customersBox.put(id, next.toMap());
  }

  Future<void> upsert(Customer customer) async {
    await LocalStorage.customersBox.put(customer.id, customer.toMap());
  }

  Future<void> delete(String customerId) async {
    await LocalStorage.customersBox.delete(customerId);
  }

  Future<void> addPurchase(String customerId, double amount) async {
    final current = LocalStorage.customersBox.get(customerId);
    if (current == null) return;

    final customer = Customer.fromMap(current);
    final next = customer.copyWith(
      totalPurchase: customer.totalPurchase + amount,
      points: customer.points + (amount ~/ 10000),
      isFavorite: customer.totalPurchase + amount > 500000,
    );

    await LocalStorage.customersBox.put(customerId, next.toMap());
  }
}
