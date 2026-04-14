import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../storage/local_storage.dart';

class ProductRepository {
  static const _uuid = Uuid();

  ValueListenable<Box<Map>> get listenable =>
      LocalStorage.productsBox.listenable();

  List<Product> getAll() {
    final list = LocalStorage.productsBox.values.map(Product.fromMap).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<Product> getAvailable() {
    return getAll().where((product) => product.available).toList();
  }

  Product? findById(String id) {
    final map = LocalStorage.productsBox.get(id);
    if (map == null) return null;
    return Product.fromMap(map);
  }

  Future<Product> create({
    required String name,
    required String category,
    required double sellPrice,
    required double costPrice,
    required int stock,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: _uuid.v4(),
      name: name.trim(),
      category: category.trim().isEmpty ? 'Umum' : category.trim(),
      sellPrice: sellPrice,
      costPrice: costPrice,
      available: true,
      stock: stock,
      createdAt: now,
      updatedAt: now,
    );

    await LocalStorage.productsBox.put(product.id, product.toMap());
    return product;
  }

  Future<void> update(Product product) async {
    await LocalStorage.productsBox.put(
      product.id,
      product.copyWith(updatedAt: DateTime.now()).toMap(),
    );
  }

  Future<void> remove(String id) async {
    await LocalStorage.productsBox.delete(id);
  }
}
