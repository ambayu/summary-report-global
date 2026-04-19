class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    this.imageBase64,
    required this.sellPrice,
    required this.costPrice,
    required this.available,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String? imageBase64;
  final double sellPrice;
  final double costPrice;
  final bool available;
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? imageBase64,
    double? sellPrice,
    double? costPrice,
    bool? available,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageBase64: imageBase64 ?? this.imageBase64,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
      available: available ?? this.available,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imageBase64': imageBase64,
      'sellPrice': sellPrice,
      'costPrice': costPrice,
      'available': available,
      'stock': stock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<dynamic, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Umum',
      imageBase64: map['imageBase64']?.toString(),
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      available: map['available'] as bool? ?? true,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
