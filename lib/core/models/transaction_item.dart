class TransactionItem {
  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.variant,
    required this.note,
  });

  final String productId;
  final String productName;
  final int qty;
  final double unitPrice;
  final String variant;
  final String note;

  double get total => unitPrice * qty;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'qty': qty,
      'unitPrice': unitPrice,
      'variant': variant,
      'note': note,
    };
  }

  factory TransactionItem.fromMap(Map<dynamic, dynamic> map) {
    return TransactionItem(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      variant: map['variant']?.toString() ?? '-',
      note: map['note']?.toString() ?? '',
    );
  }
}
