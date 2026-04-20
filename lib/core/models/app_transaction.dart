import 'enums.dart';
import 'transaction_item.dart';

class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.orderNo,
    required this.tableNo,
    required this.orderType,
    this.customerId,
    required this.customerName,
    required this.cashierName,
    required this.cashierRoleKey,
    required this.cashierRoleLabel,
    required this.items,
    required this.discountPercent,
    required this.taxPercent,
    required this.paymentMethod,
    required this.status,
    required this.paidAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderNo;
  final String tableNo;
  final String orderType;
  final String? customerId;
  final String customerName;
  final String cashierName;
  final String cashierRoleKey;
  final String cashierRoleLabel;
  final List<TransactionItem> items;
  final double discountPercent;
  final double taxPercent;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final double paidAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get taxable => subtotal - discountAmount;
  double get taxAmount => taxable * (taxPercent / 100);
  double get grandTotal => taxable + taxAmount;
  double get pendingAmount => (grandTotal - paidAmount).clamp(0, grandTotal);

  AppTransaction copyWith({
    TransactionStatus? status,
    double? paidAmount,
    DateTime? updatedAt,
  }) {
    return AppTransaction(
      id: id,
      orderNo: orderNo,
      tableNo: tableNo,
      orderType: orderType,
      customerId: customerId,
      customerName: customerName,
      cashierName: cashierName,
      cashierRoleKey: cashierRoleKey,
      cashierRoleLabel: cashierRoleLabel,
      items: items,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNo': orderNo,
      'tableNo': tableNo,
      'orderType': orderType,
      'customerId': customerId,
      'customerName': customerName,
      'cashierName': cashierName,
      'cashierRole': cashierRoleKey,
      'cashierRoleKey': cashierRoleKey,
      'cashierRoleLabel': cashierRoleLabel,
      'items': items.map((item) => item.toMap()).toList(),
      'discountPercent': discountPercent,
      'taxPercent': taxPercent,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'paidAmount': paidAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppTransaction.fromMap(Map<dynamic, dynamic> map) {
    final itemMaps = (map['items'] as List<dynamic>? ?? [])
        .cast<Map<dynamic, dynamic>>();
    final cashierRoleKey =
        map['cashierRoleKey']?.toString() ??
        map['cashierRole']?.toString() ??
        AppRole.pegawai;
    return AppTransaction(
      id: map['id']?.toString() ?? '',
      orderNo: map['orderNo']?.toString() ?? '',
      tableNo: map['tableNo']?.toString() ?? '-',
      orderType:
          map['orderType']?.toString() ??
          ((map['tableNo']?.toString() ?? '-') == '-' ? 'Take Away' : 'Dine In'),
      customerId: map['customerId']?.toString(),
      customerName: map['customerName']?.toString() ?? 'Umum',
      cashierName: map['cashierName']?.toString() ?? '-',
      cashierRoleKey: cashierRoleKey,
      cashierRoleLabel:
          map['cashierRoleLabel']?.toString() ??
          AppRole.labelForKey(cashierRoleKey),
      items: itemMaps.map(TransactionItem.fromMap).toList(),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (method) => method.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      status: TransactionStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
