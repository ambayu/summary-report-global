import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_transaction.dart';
import '../models/customer.dart';
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
    String? customerId,
    String? customerName,
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
      customerId: customerId,
      customerName: customerName?.trim().isNotEmpty == true
          ? customerName!.trim()
          : 'Umum',
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
    await _syncCustomerStats();
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
    await _syncCustomerStats();
  }

  Future<void> delete(String id) async {
    await LocalStorage.transactionsBox.delete(id);
    await _syncCustomerStats();
  }

  Future<int> deleteByMonth({required int year, required int month}) async {
    final targets = getAll().where((tx) {
      return tx.createdAt.year == year && tx.createdAt.month == month;
    }).toList();

    if (targets.isEmpty) return 0;

    for (final tx in targets) {
      await LocalStorage.transactionsBox.delete(tx.id);
    }
    await _syncCustomerStats();
    return targets.length;
  }

  Future<int> deleteByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final targets = getAll().where((tx) {
      if (tx.createdAt.isBefore(start)) return false;
      if (tx.createdAt.isAfter(end)) return false;
      return true;
    }).toList();

    if (targets.isEmpty) return 0;

    for (final tx in targets) {
      await LocalStorage.transactionsBox.delete(tx.id);
    }
    await _syncCustomerStats();
    return targets.length;
  }

  Future<int> importFromCsv(String csvContent) async {
    final rows = _splitRows(csvContent);
    if (rows.length <= 1) return 0;

    final delimiter = _detectDelimiter(rows.first);
    final headers = rows.first
        .split(delimiter)
        .map((value) => value.trim().toLowerCase())
        .toList();

    final dateIndex = headers.indexWhere(
      (header) => header.contains('tanggal') || header == 'date',
    );
    final categoryIndex = headers.indexWhere(
      (header) => header.contains('kategori') || header == 'category',
    );
    final itemIndex = headers.indexWhere(
      (header) => header.contains('item') || header.contains('produk'),
    );
    final priceIndex = headers.indexWhere(
      (header) => header.contains('harga') || header.contains('price'),
    );
    final taxIndex = headers.indexWhere((header) => header.contains('pajak'));

    if (dateIndex < 0 || itemIndex < 0 || priceIndex < 0) return 0;

    var imported = 0;

    for (final row in rows.skip(1)) {
      if (row.trim().isEmpty) continue;
      final cols = row.split(delimiter).map((c) => c.trim()).toList();
      if (cols.length <= priceIndex) continue;

      final createdAt = _parseDate(cols[dateIndex]);
      if (createdAt == null) continue;

      final itemName = cols[itemIndex];
      if (itemName.isEmpty) continue;

      final price = _parseNumber(cols[priceIndex]);
      if (price <= 0) continue;

      final tax = _normalizeImportedTax(
        price: price,
        rawTax: taxIndex >= 0 && cols.length > taxIndex ? cols[taxIndex] : '',
      );
      final category = categoryIndex >= 0 && cols.length > categoryIndex
          ? cols[categoryIndex]
          : 'Umum';
      final taxPercent = price == 0 ? 0.0 : (tax / price) * 100;

      final tx = AppTransaction(
        id: _uuid.v4(),
        orderNo:
            'IMP-${createdAt.millisecondsSinceEpoch.toString().substring(6)}',
        tableNo: category.isEmpty ? '-' : category,
        customerId: null,
        customerName: 'Umum',
        cashierName: 'Import CSV',
        cashierRole: UserRole.admin,
        items: [
          TransactionItem(
            productId: '',
            productName: itemName,
            qty: 1,
            unitPrice: price,
            note: 'Imported from CSV',
          ),
        ],
        discountPercent: 0,
        taxPercent: taxPercent,
        servicePercent: 0,
        paymentMethod: PaymentMethod.cash,
        status: TransactionStatus.lunas,
        paidAmount: price + tax,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      await LocalStorage.transactionsBox.put(tx.id, tx.toMap());
      imported += 1;
    }

    await _syncCustomerStats();
    return imported;
  }

  Future<int> importFromXlsx(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return 0;

    final sheet = excel.tables.values.first;
    if (sheet.rows.length <= 1) return 0;

    final headers = sheet.rows.first
        .map((cell) => _excelCellText(cell).toLowerCase())
        .toList();

    final dateIndex = headers.indexWhere(
      (header) => header.contains('tanggal') || header == 'date',
    );
    final categoryIndex = headers.indexWhere(
      (header) => header.contains('kategori') || header == 'category',
    );
    final itemIndex = headers.indexWhere(
      (header) => header.contains('item') || header.contains('produk'),
    );
    final priceIndex = headers.indexWhere(
      (header) => header.contains('harga') || header.contains('price'),
    );
    final taxIndex = headers.indexWhere((header) => header.contains('pajak'));

    if (dateIndex < 0 || itemIndex < 0 || priceIndex < 0) return 0;

    var imported = 0;

    for (final row in sheet.rows.skip(1)) {
      final dateRaw = _excelCellByIndex(row, dateIndex);
      final itemName = _excelCellByIndex(row, itemIndex);
      final priceRaw = _excelCellByIndex(row, priceIndex);
      final categoryRaw = _excelCellByIndex(row, categoryIndex);
      final taxRaw = _excelCellByIndex(row, taxIndex);

      final createdAt = _parseDate(dateRaw);
      if (createdAt == null) continue;
      if (itemName.trim().isEmpty) continue;

      final price = _parseNumber(priceRaw);
      if (price <= 0) continue;

      final tax = _normalizeImportedTax(price: price, rawTax: taxRaw);
      final taxPercent = price == 0 ? 0.0 : (tax / price) * 100;
      final category = categoryRaw.trim().isEmpty ? 'Umum' : categoryRaw.trim();

      final tx = AppTransaction(
        id: _uuid.v4(),
        orderNo:
            'IMP-${createdAt.millisecondsSinceEpoch.toString().substring(6)}',
        tableNo: category,
        customerId: null,
        customerName: 'Umum',
        cashierName: 'Import XLSX',
        cashierRole: UserRole.admin,
        items: [
          TransactionItem(
            productId: '',
            productName: itemName.trim(),
            qty: 1,
            unitPrice: price,
            note: 'Imported from XLSX',
          ),
        ],
        discountPercent: 0,
        taxPercent: taxPercent,
        servicePercent: 0,
        paymentMethod: PaymentMethod.cash,
        status: TransactionStatus.lunas,
        paidAmount: price + tax,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      await LocalStorage.transactionsBox.put(tx.id, tx.toMap());
      imported += 1;
    }

    await _syncCustomerStats();
    return imported;
  }

  String exportToCsv({int? year}) {
    final buffer = StringBuffer('Tanggal,Kategori,Item,Harga,Pajak 10%\n');

    for (final tx in getAll().reversed) {
      if (year != null && tx.createdAt.year != year) continue;
      if (tx.status == TransactionStatus.batal) continue;

      for (final item in tx.items) {
        final map = LocalStorage.productsBox.get(item.productId);
        final category = map == null
            ? (tx.tableNo == '-' ? 'Umum' : tx.tableNo)
            : (map['category']?.toString() ?? 'Umum');
        final lineTax = tx.subtotal <= 0
            ? 0.0
            : tx.taxAmount * (item.total / tx.subtotal);

        buffer.writeln(
          '${_formatDate(tx.createdAt)},'
          '${_csvCell(category)},'
          '${_csvCell(item.productName)},'
          '${_formatNumber(item.total)},'
          '${_formatNumber(lineTax)}',
        );
      }
    }

    return buffer.toString();
  }

  String exportFilteredToCsv({
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final buffer = StringBuffer(
      'Tanggal,Order,Meja,Status,Metode,Item,Qty,Harga,Subtotal,Pajak,Service,Total\n',
    );

    for (final tx in getAll().reversed) {
      if (status != null && tx.status != status) continue;
      if (!_isWithinRange(tx.createdAt, startDate, endDate)) continue;

      for (final item in tx.items) {
        buffer.writeln(
          '${_formatDate(tx.createdAt)},'
          '${_csvCell(tx.orderNo)},'
          '${_csvCell(tx.tableNo)},'
          '${_csvCell(tx.status.label)},'
          '${_csvCell(tx.paymentMethod.label)},'
          '${_csvCell(item.productName)},'
          '${item.qty},'
          '${_formatNumber(item.unitPrice)},'
          '${_formatNumber(item.total)},'
          '${_formatNumber(tx.taxAmount)},'
          '${_formatNumber(tx.serviceAmount)},'
          '${_formatNumber(tx.grandTotal)}',
        );
      }
    }

    return buffer.toString();
  }

  Uint8List exportReportToXlsx({
    int? year,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan'];
    var totalHarga = 0.0;
    var totalPajak = 0.0;

    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Kategori'),
      TextCellValue('Item'),
      TextCellValue('Harga'),
      TextCellValue('Pajak 10%'),
    ]);

    for (final tx in getAll().reversed) {
      if (year != null && tx.createdAt.year != year) continue;
      if (!_isWithinRange(tx.createdAt, startDate, endDate)) continue;
      if (tx.status == TransactionStatus.batal) continue;

      for (final item in tx.items) {
        final map = LocalStorage.productsBox.get(item.productId);
        final category = map == null
            ? (tx.tableNo == '-' ? 'Umum' : tx.tableNo)
            : (map['category']?.toString() ?? 'Umum');
        final lineTax = tx.subtotal <= 0
            ? 0.0
            : tx.taxAmount * (item.total / tx.subtotal);
        totalHarga += item.total;
        totalPajak += lineTax;

        sheet.appendRow([
          TextCellValue(_formatDate(tx.createdAt)),
          TextCellValue(category),
          TextCellValue(item.productName),
          DoubleCellValue(item.total),
          DoubleCellValue(lineTax),
        ]);
      }
    }

    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('TOTAL PER KOLOM'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalHarga),
      DoubleCellValue(totalPajak),
    ]);
    sheet.appendRow([
      TextCellValue('TOTAL SELURUHNYA'),
      TextCellValue(''),
      TextCellValue('Harga + Pajak'),
      DoubleCellValue(totalHarga + totalPajak),
      TextCellValue(''),
    ]);

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  List<AppTransaction> forDate(DateTime date) {
    return getAll().where((item) {
      return item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day;
    }).toList();
  }

  List<String> _splitRows(String csvContent) {
    return csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
  }

  String _detectDelimiter(String headerRow) {
    if (headerRow.contains('\t')) return '\t';
    if (headerRow.contains(';')) return ';';
    return ',';
  }

  DateTime? _parseDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
    if (slash != null) {
      final day = int.parse(slash.group(1)!);
      final month = int.parse(slash.group(2)!);
      final year = int.parse(slash.group(3)!);
      return DateTime(year, month, day);
    }

    final dash = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text);
    if (dash != null) {
      final year = int.parse(dash.group(1)!);
      final month = int.parse(dash.group(2)!);
      final day = int.parse(dash.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  double _parseNumber(String raw) {
    final normalized = raw
        .replaceAll(RegExp(r'[^0-9,.-]'), '')
        .replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double _normalizeImportedTax({
    required double price,
    required String rawTax,
  }) {
    if (price <= 0) return 0;

    final parsedTax = _parseNumber(rawTax);
    if (rawTax.trim().isEmpty || parsedTax <= 0) {
      return price * 0.10;
    }

    // Guard against broken imports where the tax cell is read as the same
    // nominal value as price, which would double the total in the app.
    if (parsedTax >= price) {
      return price * 0.10;
    }

    return parsedTax;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  String _excelCellByIndex(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _excelCellText(row[index]);
  }

  String _excelCellText(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  bool _isWithinRange(DateTime date, DateTime? startDate, DateTime? endDate) {
    final start = startDate == null
        ? null
        : DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate == null
        ? null
        : DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    if (start != null && date.isBefore(start)) return false;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }

  Future<void> _syncCustomerStats() async {
    final customers = LocalStorage.customersBox.values
        .map(Customer.fromMap)
        .toList();
    if (customers.isEmpty) return;

    final transactions = getAll();
    for (final customer in customers) {
      final paidTransactions = transactions.where((tx) {
        return tx.customerId == customer.id && tx.status == TransactionStatus.lunas;
      });

      final totalPurchase = paidTransactions.fold<double>(
        0,
        (sum, tx) => sum + tx.grandTotal,
      );
      final points = totalPurchase ~/ 10000;
      final next = customer.copyWith(
        totalPurchase: totalPurchase,
        points: points,
        isFavorite: totalPurchase > 500000,
      );
      await LocalStorage.customersBox.put(customer.id, next.toMap());
    }
  }
}
