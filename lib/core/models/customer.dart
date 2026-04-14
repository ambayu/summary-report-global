class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalPurchase,
    required this.points,
    required this.isFavorite,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final double totalPurchase;
  final int points;
  final bool isFavorite;
  final DateTime createdAt;

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    double? totalPurchase,
    int? points,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalPurchase: totalPurchase ?? this.totalPurchase,
      points: points ?? this.points,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'totalPurchase': totalPurchase,
      'points': points,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<dynamic, dynamic> map) {
    return Customer(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      totalPurchase: (map['totalPurchase'] as num?)?.toDouble() ?? 0,
      points: (map['points'] as num?)?.toInt() ?? 0,
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
