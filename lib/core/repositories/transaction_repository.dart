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
  static const _salesRecapSheetName = 'Rekap Penjualan';

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
    required String orderType,
    String? customerId,
    String? customerName,
    required List<TransactionItem> items,
    required double discountPercent,
    required double taxPercent,
    required PaymentMethod paymentMethod,
    required TransactionStatus status,
    required UserSession cashier,
  }) async {
    final now = DateTime.now();
    final tx = AppTransaction(
      id: _uuid.v4(),
      orderNo: 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}',
      tableNo: orderType == 'Take Away'
          ? '-'
          : (tableNo.trim().isEmpty ? '-' : tableNo.trim()),
      orderType: orderType,
      customerId: customerId,
      customerName: customerName?.trim().isNotEmpty == true
          ? customerName!.trim()
          : 'Umum',
      cashierName: cashier.name,
      cashierRoleKey: cashier.roleKey,
      cashierRoleLabel: cashier.roleLabel,
      items: items,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
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
    final headers = rows.first.split(delimiter).map(_normalizeHeader).toList();
    final indexes = _resolveImportIndexes(headers);
    final dateIndex = indexes.date;
    final categoryIndex = indexes.category;
    final orderIndex = indexes.order;
    final itemIndex = indexes.item;
    final variantIndex = indexes.variant;
    final qtyIndex = indexes.qty;
    final discountIndex = indexes.discount;
    final orderTypeIndex = indexes.orderType;
    final subtotalIndex = indexes.subtotal;
    final priceIndex = indexes.price;
    final taxIndex = indexes.tax;

    if (dateIndex < 0 || itemIndex < 0 || priceIndex < 0) return 0;

    final groupedRows = <String, List<_ImportedLine>>{};

    for (final row in rows.skip(1)) {
      if (row.trim().isEmpty) continue;
      final cols = row.split(delimiter).map((c) => c.trim()).toList();
      if (cols.length <= priceIndex) continue;

      final createdAt = _parseDate(cols[dateIndex]);
      if (createdAt == null) continue;

      final itemName = cols[itemIndex];
      if (itemName.isEmpty) continue;

      final qtyRaw = qtyIndex >= 0 && cols.length > qtyIndex
          ? cols[qtyIndex]
          : '1';
      final qty = _parseNumber(qtyRaw).round().clamp(1, 999999);
      final price = _parseNumber(cols[priceIndex]);
      if (price <= 0) continue;

      final lineSubtotal = subtotalIndex >= 0 && cols.length > subtotalIndex
          ? _parseNumber(cols[subtotalIndex])
          : price * qty;
      final discount = discountIndex >= 0 && cols.length > discountIndex
          ? _parseNumber(cols[discountIndex])
          : ((price * qty) - lineSubtotal).clamp(0, price * qty).toDouble();
      final tax = _normalizeImportedTax(
        price: lineSubtotal > 0 ? lineSubtotal : price * qty,
        rawTax: taxIndex >= 0 && cols.length > taxIndex ? cols[taxIndex] : '',
      );
      final category = categoryIndex >= 0 && cols.length > categoryIndex
          ? cols[categoryIndex]
          : 'Umum';
      final orderNo = orderIndex >= 0 && cols.length > orderIndex
          ? cols[orderIndex].trim()
          : 'IMP-${createdAt.millisecondsSinceEpoch.toString().substring(6)}';
      final orderType = orderTypeIndex >= 0 && cols.length > orderTypeIndex
          ? cols[orderTypeIndex].trim()
          : '-';
      final variant = variantIndex >= 0 && cols.length > variantIndex
          ? cols[variantIndex].trim()
          : '-';
      final key = '${_formatDate(createdAt)}|$orderNo|$orderType';

      groupedRows
          .putIfAbsent(key, () => [])
          .add(
            _ImportedLine(
              createdAt: createdAt,
              orderNo: orderNo,
              category: category.trim().isEmpty ? 'Umum' : category.trim(),
              productName: itemName.trim(),
              variant: variant,
              qty: qty,
              unitPrice: price,
              discountAmount: discount,
              taxAmount: tax,
              orderType: orderType,
            ),
          );
    }

    final imported = await _persistImportedGroups(groupedRows);
    await _syncCustomerStats();
    return imported;
  }

  Future<int> importFromXlsx(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return 0;

    final sheet = _findImportSheet(excel);
    if (sheet == null) return 0;
    if (sheet.rows.length <= 1) return 0;

    final headers = sheet.rows.first
        .map((cell) => _normalizeHeader(_excelCellText(cell)))
        .toList();
    final indexes = _resolveImportIndexes(headers);
    final dateIndex = indexes.date;
    final categoryIndex = indexes.category;
    final orderIndex = indexes.order;
    final itemIndex = indexes.item;
    final variantIndex = indexes.variant;
    final qtyIndex = indexes.qty;
    final discountIndex = indexes.discount;
    final orderTypeIndex = indexes.orderType;
    final subtotalIndex = indexes.subtotal;
    final priceIndex = indexes.price;
    final taxIndex = indexes.tax;

    if (dateIndex < 0 || itemIndex < 0 || priceIndex < 0) return 0;

    final groupedRows = <String, List<_ImportedLine>>{};

    for (final row in sheet.rows.skip(1)) {
      final dateRaw = _excelCellByIndex(row, dateIndex);
      final itemName = _excelCellByIndex(row, itemIndex);
      final priceRaw = _excelCellByIndex(row, priceIndex);
      final categoryRaw = _excelCellByIndex(row, categoryIndex);
      final taxRaw = _excelCellByIndex(row, taxIndex);
      final orderRaw = _excelCellByIndex(row, orderIndex);
      final variantRaw = _excelCellByIndex(row, variantIndex);
      final qtyRaw = _excelCellByIndex(row, qtyIndex);
      final discountRaw = _excelCellByIndex(row, discountIndex);
      final orderTypeRaw = _excelCellByIndex(row, orderTypeIndex);
      final subtotalRaw = _excelCellByIndex(row, subtotalIndex);

      final createdAt = _parseExcelDateCell(
        row,
        dateIndex,
        fallbackRaw: dateRaw,
      );
      if (createdAt == null) continue;
      if (itemName.trim().isEmpty) continue;

      final qty = _parseNumber(qtyRaw).round().clamp(1, 999999);
      final price = _parseNumber(priceRaw);
      if (price <= 0) continue;

      final lineSubtotal = subtotalRaw.trim().isEmpty
          ? price * qty
          : _parseNumber(subtotalRaw);
      final discount = discountRaw.trim().isEmpty
          ? ((price * qty) - lineSubtotal).clamp(0, price * qty).toDouble()
          : _parseNumber(discountRaw);
      final tax = _normalizeImportedTax(
        price: lineSubtotal > 0 ? lineSubtotal : price * qty,
        rawTax: taxRaw,
      );
      final category = categoryRaw.trim().isEmpty ? 'Umum' : categoryRaw.trim();
      final orderNo = orderRaw.trim().isEmpty
          ? 'IMP-${createdAt.millisecondsSinceEpoch.toString().substring(6)}'
          : orderRaw.trim();
      final orderType = orderTypeRaw.trim().isEmpty ? '-' : orderTypeRaw.trim();
      final key = '${_formatDate(createdAt)}|$orderNo|$orderType';

      groupedRows
          .putIfAbsent(key, () => [])
          .add(
            _ImportedLine(
              createdAt: createdAt,
              orderNo: orderNo,
              category: category,
              productName: itemName.trim(),
              variant: variantRaw.trim(),
              qty: qty,
              unitPrice: price,
              discountAmount: discount,
              taxAmount: tax,
              orderType: orderType,
            ),
          );
    }

    final imported = await _persistImportedGroups(groupedRows);
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
      'Tanggal,Order,Meja,Status,Metode,Item,Qty,Harga,Subtotal,Pajak,Total\n',
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
          '${_formatNumber(tx.grandTotal)}',
        );
      }
    }

    return buffer.toString();
  }

  Uint8List exportFilteredToXlsx({
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final excel = _createWorkbook('Rekap Penjualan');
    final sheet = excel['Rekap Penjualan'];
    var rowIndex = 0;

    _appendSalesRecapHeader(sheet, rowIndex);
    rowIndex += 1;

    for (final tx in getAll().reversed) {
      if (status != null && tx.status != status) continue;
      if (!_isWithinRange(tx.createdAt, startDate, endDate)) continue;
      if (!_shouldIncludeInSalesRecap(tx, requestedStatus: status)) continue;

      rowIndex = _appendSalesRecapRows(sheet, tx, rowIndex);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  Uint8List exportReportToXlsx({
    int? year,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final excel = _createWorkbook('Rekap Penjualan');
    final sheet = excel['Rekap Penjualan'];
    var rowIndex = 0;

    _appendSalesRecapHeader(sheet, rowIndex);
    rowIndex += 1;

    for (final tx in getAll().reversed) {
      if (year != null && tx.createdAt.year != year) continue;
      if (!_isWithinRange(tx.createdAt, startDate, endDate)) continue;
      if (!_shouldIncludeInSalesRecap(tx)) continue;

      rowIndex = _appendSalesRecapRows(sheet, tx, rowIndex);
    }

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

    final numeric = double.tryParse(text.replaceAll(',', '.'));
    if (numeric != null && numeric > 20000 && numeric < 80000) {
      final wholeDays = numeric.floor();
      final seconds = ((numeric - wholeDays) * Duration.secondsPerDay).round();
      return DateTime(
        1899,
        12,
        30,
      ).add(Duration(days: wholeDays, seconds: seconds));
    }

    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
    if (slash != null) {
      final day = int.parse(slash.group(1)!);
      final month = int.parse(slash.group(2)!);
      final year = int.parse(slash.group(3)!);
      return DateTime(year, month, day);
    }

    final dashDayFirst = RegExp(
      r'^(\d{1,2})-(\d{1,2})-(\d{4})$',
    ).firstMatch(text);
    if (dashDayFirst != null) {
      final day = int.parse(dashDayFirst.group(1)!);
      final month = int.parse(dashDayFirst.group(2)!);
      final year = int.parse(dashDayFirst.group(3)!);
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

  Sheet? _findImportSheet(Excel excel) {
    for (final entry in excel.tables.entries) {
      if (_normalizeHeader(entry.key) ==
          _normalizeHeader(_salesRecapSheetName)) {
        return entry.value;
      }
    }

    for (final sheet in excel.tables.values) {
      if (sheet.rows.isEmpty) continue;
      final headers = sheet.rows.first
          .map((cell) => _normalizeHeader(_excelCellText(cell)))
          .toList();
      final indexes = _resolveImportIndexes(headers);
      if (indexes.date >= 0 && indexes.item >= 0 && indexes.price >= 0) {
        return sheet;
      }
    }

    return null;
  }

  _ImportIndexes _resolveImportIndexes(List<String> headers) {
    return _ImportIndexes(
      date: _findHeaderIndex(headers, const ['tanggal', 'date']),
      category: _findHeaderIndex(headers, const ['kategori', 'category']),
      order: _findHeaderIndex(headers, const [
        'kode struk',
        'order',
        'kode order',
      ]),
      item: _findHeaderIndex(headers, const [
        'barang',
        'item',
        'produk',
        'menu',
      ]),
      variant: _findHeaderIndex(headers, const ['varian', 'variant']),
      qty: _findHeaderIndex(headers, const ['qty', 'jumlah']),
      discount: _findHeaderIndex(headers, const ['diskon', 'discount']),
      orderType: _findHeaderIndex(headers, const [
        'jenis pesanan',
        'order type',
        'meja',
      ]),
      subtotal: _findHeaderIndex(headers, const ['sub total', 'subtotal']),
      price: _findHeaderIndex(headers, const ['harga', 'price']),
      tax: _findHeaderIndex(headers, const ['pajak', 'tax']),
    );
  }

  int _findHeaderIndex(List<String> headers, List<String> aliases) {
    return headers.indexWhere((header) {
      for (final alias in aliases) {
        final normalizedAlias = _normalizeHeader(alias);
        if (header == normalizedAlias || header.contains(normalizedAlias)) {
          return true;
        }
      }
      return false;
    });
  }

  String _normalizeHeader(String raw) {
    return raw
        .replaceAll('\uFEFF', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  Excel _createWorkbook(String sheetName) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    _configureSalesRecapSheet(excel[sheetName]);
    return excel;
  }

  void _appendSalesRecapHeader(Sheet sheet, int rowIndex) {
    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Kategori'),
      TextCellValue('Kode Struk'),
      TextCellValue('Barang'),
      TextCellValue('Varian'),
      TextCellValue('Qty'),
      TextCellValue('Harga'),
      TextCellValue('Diskon'),
      TextCellValue('Jenis Pesanan'),
      TextCellValue('Sub Total'),
      TextCellValue('Pajak'),
    ]);
    _styleSalesRecapHeader(sheet, rowIndex);
  }

  int _appendSalesRecapRows(Sheet sheet, AppTransaction tx, int rowIndex) {
    for (final item in tx.items) {
      final baseTotal = item.total;
      final ratio = tx.subtotal <= 0 ? 0.0 : baseTotal / tx.subtotal;
      final lineDiscount = tx.discountAmount * ratio;
      final lineTax = tx.taxAmount * ratio;
      final netSubtotal = baseTotal - lineDiscount;

      sheet.appendRow([
        TextCellValue(_formatDate(tx.createdAt)),
        TextCellValue(_resolveCategory(tx, item)),
        TextCellValue(tx.orderNo),
        TextCellValue(item.productName),
        TextCellValue(_resolveVariant(item)),
        IntCellValue(item.qty),
        DoubleCellValue(item.unitPrice),
        DoubleCellValue(lineDiscount),
        TextCellValue(_resolveOrderType(tx)),
        DoubleCellValue(netSubtotal),
        DoubleCellValue(lineTax),
      ]);
      _styleSalesRecapDataRow(sheet, rowIndex);
      rowIndex += 1;
    }
    return rowIndex;
  }

  void _configureSalesRecapSheet(Sheet sheet) {
    sheet.setDefaultColumnWidth(14);
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 24);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 8);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 14);
    sheet.setColumnWidth(8, 16);
    sheet.setColumnWidth(9, 16);
    sheet.setColumnWidth(10, 14);

    for (var index = 0; index <= 10; index++) {
      sheet.setColumnAutoFit(index);
    }
  }

  void _styleSalesRecapHeader(Sheet sheet, int rowIndex) {
    sheet.setRowHeight(rowIndex, 24);
    final style = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFB3261E'),
      fontColorHex: ExcelColor.white,
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FF7F1D1D'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FF7F1D1D'),
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FF7F1D1D'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FF7F1D1D'),
      ),
    );

    for (var columnIndex = 0; columnIndex <= 10; columnIndex++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: rowIndex,
        ),
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
            )
            .value,
        cellStyle: style,
      );
    }
  }

  void _styleSalesRecapDataRow(Sheet sheet, int rowIndex) {
    final textStyle = CellStyle(
      fontSize: 10,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFE5E7EB'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFE5E7EB'),
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFE5E7EB'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFE5E7EB'),
      ),
    );
    final centeredStyle = textStyle.copyWith(
      horizontalAlignVal: HorizontalAlign.Center,
    );
    final numericStyle = textStyle.copyWith(
      horizontalAlignVal: HorizontalAlign.Right,
    );

    sheet.setRowHeight(rowIndex, 22);
    for (final columnIndex in [0, 1, 2, 3, 4, 8]) {
      _updateStyledCell(sheet, rowIndex, columnIndex, textStyle);
    }
    _updateStyledCell(sheet, rowIndex, 5, centeredStyle);
    for (final columnIndex in [6, 7, 9, 10]) {
      _updateStyledCell(sheet, rowIndex, columnIndex, numericStyle);
    }
  }

  void _updateStyledCell(
    Sheet sheet,
    int rowIndex,
    int columnIndex,
    CellStyle style,
  ) {
    final cellIndex = CellIndex.indexByColumnRow(
      columnIndex: columnIndex,
      rowIndex: rowIndex,
    );
    sheet.updateCell(cellIndex, sheet.cell(cellIndex).value, cellStyle: style);
  }

  String _resolveCategory(AppTransaction tx, TransactionItem item) {
    final importedCategory = _importMeta(item.note, 'category');
    if (importedCategory != null && importedCategory.isNotEmpty) {
      return importedCategory;
    }

    final map = LocalStorage.productsBox.get(item.productId);
    if (map == null) {
      return tx.tableNo == '-' ? 'Umum' : tx.tableNo;
    }
    return map['category']?.toString() ?? 'Umum';
  }

  String _resolveVariant(TransactionItem item) {
    final storedVariant = item.variant.trim();
    if (storedVariant.isNotEmpty && storedVariant != '-') {
      return storedVariant;
    }

    final importedVariant = _importMeta(item.note, 'variant');
    if (importedVariant != null && importedVariant.isNotEmpty) {
      return importedVariant;
    }

    final note = item.note.trim();
    if (note.isEmpty) return '-';
    if (note.toLowerCase().startsWith('imported from')) return '-';
    return note;
  }

  String _resolveOrderType(AppTransaction tx) {
    final explicit = tx.orderType.trim();
    if (explicit.isNotEmpty) return explicit;
    return tx.tableNo == '-' ? 'Take Away' : 'Dine In';
  }

  Future<int> _persistImportedGroups(
    Map<String, List<_ImportedLine>> groupedRows,
  ) async {
    var imported = 0;

    for (final lines in groupedRows.values) {
      if (lines.isEmpty) continue;

      final first = lines.first;
      final grossSubtotal = lines.fold<double>(
        0,
        (sum, line) => sum + (line.unitPrice * line.qty),
      );
      final discountAmount = lines.fold<double>(
        0,
        (sum, line) => sum + line.discountAmount,
      );
      final taxable = (grossSubtotal - discountAmount).clamp(
        0,
        double.infinity,
      );
      final taxAmount = lines.fold<double>(
        0,
        (sum, line) => sum + line.taxAmount,
      );
      final discountPercent = grossSubtotal <= 0
          ? 0.0
          : (discountAmount / grossSubtotal) * 100;
      final taxPercent = taxable <= 0 ? 0.0 : (taxAmount / taxable) * 100;

      final items = lines
          .map(
            (line) => TransactionItem(
              productId: '',
              productName: line.productName,
              qty: line.qty,
              unitPrice: line.unitPrice,
              variant: line.variant,
              note: _buildImportedItemNote(
                category: line.category,
                variant: line.variant,
              ),
            ),
          )
          .toList();

      final tx = AppTransaction(
        id: _uuid.v4(),
        orderNo: first.orderNo,
        tableNo: _tableNoFromOrderType(first.orderType),
        orderType: first.orderType.trim().isEmpty
            ? 'Take Away'
            : first.orderType,
        customerId: null,
        customerName: 'Umum',
        cashierName: '',
        cashierRoleKey: '',
        cashierRoleLabel: '',
        items: items,
        discountPercent: discountPercent,
        taxPercent: taxPercent,
        paymentMethod: PaymentMethod.cash,
        status: TransactionStatus.lunas,
        paidAmount: taxable + taxAmount,
        createdAt: first.createdAt,
        updatedAt: first.createdAt,
      );

      await LocalStorage.transactionsBox.put(tx.id, tx.toMap());
      imported += 1;
    }

    return imported;
  }

  String _tableNoFromOrderType(String orderType) {
    final normalized = orderType.trim().toLowerCase();
    if (normalized.contains('take away') || normalized.contains('takeaway')) {
      return '-';
    }
    return 'Dine In';
  }

  String _buildImportedItemNote({
    required String category,
    required String variant,
  }) {
    final safeCategory = category.trim().isEmpty ? 'Umum' : category.trim();
    final safeVariant = variant.trim().isEmpty ? '-' : variant.trim();
    return '__import__|category=$safeCategory|variant=$safeVariant';
  }

  String? _importMeta(String note, String key) {
    if (!note.startsWith('__import__|')) return null;

    for (final part in note.split('|').skip(1)) {
      final separator = part.indexOf('=');
      if (separator <= 0) continue;

      final currentKey = part.substring(0, separator).trim();
      if (currentKey != key) continue;
      return part.substring(separator + 1).trim();
    }

    return null;
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

  DateTime? _parseExcelDateCell(
    List<Data?> row,
    int index, {
    required String fallbackRaw,
  }) {
    if (index < 0 || index >= row.length) {
      return _parseDate(fallbackRaw);
    }

    final cell = row[index];
    if (cell?.value == null) {
      return _parseDate(fallbackRaw);
    }

    final value = cell!.value;
    if (value is DateCellValue) {
      return value.asDateTimeLocal();
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal();
    }

    return _parseDate(value.toString());
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

  bool _shouldIncludeInSalesRecap(
    AppTransaction tx, {
    TransactionStatus? requestedStatus,
  }) {
    if (requestedStatus == TransactionStatus.batal) {
      return tx.status == TransactionStatus.batal;
    }
    return tx.status != TransactionStatus.batal;
  }

  Future<void> _syncCustomerStats() async {
    final customers = LocalStorage.customersBox.values
        .map(Customer.fromMap)
        .toList();
    if (customers.isEmpty) return;

    final transactions = getAll();
    for (final customer in customers) {
      final paidTransactions = transactions.where((tx) {
        return tx.customerId == customer.id &&
            tx.status == TransactionStatus.lunas;
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

class _ImportedLine {
  const _ImportedLine({
    required this.createdAt,
    required this.orderNo,
    required this.category,
    required this.productName,
    required this.variant,
    required this.qty,
    required this.unitPrice,
    required this.discountAmount,
    required this.taxAmount,
    required this.orderType,
  });

  final DateTime createdAt;
  final String orderNo;
  final String category;
  final String productName;
  final String variant;
  final int qty;
  final double unitPrice;
  final double discountAmount;
  final double taxAmount;
  final String orderType;
}

class _ImportIndexes {
  const _ImportIndexes({
    required this.date,
    required this.category,
    required this.order,
    required this.item,
    required this.variant,
    required this.qty,
    required this.discount,
    required this.orderType,
    required this.subtotal,
    required this.price,
    required this.tax,
  });

  final int date;
  final int category;
  final int order;
  final int item;
  final int variant;
  final int qty;
  final int discount;
  final int orderType;
  final int subtotal;
  final int price;
  final int tax;
}
