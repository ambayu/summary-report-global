import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart';

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
    String? imageBase64,
    required double sellPrice,
    required double costPrice,
    required int stock,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: _uuid.v4(),
      name: name.trim(),
      category: category.trim().isEmpty ? 'Umum' : category.trim(),
      imageBase64: imageBase64,
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

  Future<int> importFromXlsx(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return 0;

    final existing = getAll();
    final existingByName = {
      for (final item in existing) item.name.toLowerCase().trim(): item,
    };

    var importedCount = 0;
    for (final sheet in excel.tables.values) {
      if (sheet.rows.isEmpty) continue;

      final headers = sheet.rows.first
          .map((cell) => _cellToText(cell?.value).toLowerCase().trim())
          .toList();

      int findHeader(List<String> keywords) {
        for (var i = 0; i < headers.length; i++) {
          final h = headers[i];
          if (h.isEmpty) continue;
          if (keywords.any((key) => h.contains(key))) return i;
        }
        return -1;
      }

      final nameIndex = findHeader([
        'menu',
        'nama',
        'product',
        'produk',
        'item',
      ]);
      if (nameIndex < 0) continue;
      final categoryIndex = findHeader(['kategori', 'category', 'jenis']);
      final priceIndex = findHeader(['price', 'harga', 'sell']);
      final costIndex = findHeader(['modal', 'cost', 'hpp']);
      final stockIndex = findHeader(['stok', 'stock']);
      final priceInK = priceIndex >= 0 && headers[priceIndex].contains('(k)');
      final costInK = costIndex >= 0 && headers[costIndex].contains('(k)');

      for (final row in sheet.rows.skip(1)) {
        final name = _cellAt(row, nameIndex);
        if (name.isEmpty) continue;

        final category = categoryIndex >= 0 ? _cellAt(row, categoryIndex) : '';
        final sellPrice = priceIndex >= 0
            ? _priceFromCell(row[priceIndex], isK: priceInK)
            : 0.0;
        final costPrice = costIndex >= 0
            ? _priceFromCell(row[costIndex], isK: costInK)
            : 0.0;
        final stock = stockIndex >= 0 ? _intFromCell(row[stockIndex]) : 0;

        final now = DateTime.now();
        final key = name.toLowerCase().trim();
        final existingItem = existingByName[key];
        if (existingItem != null) {
          final updated = existingItem.copyWith(
            name: name,
            category: category.isEmpty ? existingItem.category : category,
            sellPrice: sellPrice > 0 ? sellPrice : existingItem.sellPrice,
            costPrice: costPrice >= 0 ? costPrice : existingItem.costPrice,
            stock: stock >= 0 ? stock : existingItem.stock,
            updatedAt: now,
          );
          await LocalStorage.productsBox.put(updated.id, updated.toMap());
          existingByName[key] = updated;
        } else {
          final product = Product(
            id: _uuid.v4(),
            name: name.trim(),
            category: category.trim().isEmpty ? 'Umum' : category.trim(),
            imageBase64: null,
            sellPrice: sellPrice,
            costPrice: costPrice,
            available: true,
            stock: stock,
            createdAt: now,
            updatedAt: now,
          );
          await LocalStorage.productsBox.put(product.id, product.toMap());
          existingByName[key] = product;
        }
        importedCount++;
      }
    }

    return importedCount;
  }

  String _cellAt(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _cellToText(row[index]?.value).trim();
  }

  String _cellToText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  double _priceFromCell(Data? cell, {required bool isK}) {
    final raw = _cellToText(cell?.value).toLowerCase().trim();
    if (raw.isEmpty) return 0;

    final onlyNumber = raw.replaceAll(RegExp(r'[^0-9.,-]'), '');
    final normalized = onlyNumber.replaceAll('.', '').replaceAll(',', '.');
    final parsed = double.tryParse(normalized) ?? 0;
    final hasKUnit = raw.contains('k');
    if (isK || hasKUnit) return parsed * 1000;
    return parsed;
  }

  int _intFromCell(Data? cell) {
    final raw = _cellToText(cell?.value);
    final normalized = raw.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(normalized) ?? 0;
  }
}
