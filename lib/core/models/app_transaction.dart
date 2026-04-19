import 'enums.dart';
import 'transaction_item.dart';

class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.orderNo,
    required this.tableNo,
    this.customerId,
    required this.customerName,
    required this.cashierName,
    required this.cashierRole,
    required this.items,
    required this.discountPercent,
    required this.taxPercent,
    required this.servicePercent,
    required this.paymentMethod,
    required this.status,
    required this.paidAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderNo;
  final String tableNo;
  final String? customerId;
  final String customerName;
  final String cashierName;
  final UserRole cashierRole;
  final List<TransactionItem> items;
  final double discountPercent;
  final double taxPercent;
  final double servicePercent;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final double paidAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get taxable => subtotal - discountAmount;
  double get taxAmount => taxable * (taxPercent / 100);
  double get serviceAmount => taxable * (servicePercent / 100);
  double get grandTotal => taxable + taxAmount + serviceAmount;
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
      customerId: customerId,
      customerName: customerName,
      cashierName: cashierName,
      cashierRole: cashierRole,
      items: items,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
      servicePercent: servicePercent,
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
      'customerId': customerId,
      'customerName': customerName,
      'cashierName': cashierName,
      'cashierRole': cashierRole.name,
      'items': items.map((item) => item.toMap()).toList(),
      'discountPercent': discountPercent,
      'taxPercent': taxPercent,
      'servicePercent': servicePercent,
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
    return AppTransaction(
      id: map['id']?.toString() ?? '',
      orderNo: map['orderNo']?.toString() ?? '',
      tableNo: map['tableNo']?.toString() ?? '-',
      customerId: map['customerId']?.toString(),
      customerName: map['customerName']?.toString() ?? 'Umum',
      cashierName: map['cashierName']?.toString() ?? '-',
      cashierRole: UserRole.values.firstWhere(
        (role) => role.name == map['cashierRole'],
        orElse: () => UserRole.kasir,
      ),
      items: itemMaps.map(TransactionItem.fromMap).toList(),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
      servicePercent: (map['servicePercent'] as num?)?.toDouble() ?? 0,
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
