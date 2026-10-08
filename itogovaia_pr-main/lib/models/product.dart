class Product {
  final int id;
  final String name;
  final String sku;
  final int supplierId;
  final List<int> categoryIds;
  final List<int> brandIds;
  final double price;
  final int stock;
  final double rating;
  final DateTime? deletedAt;
  final String? supplierName;
  final List<String> brandNames;
  final List<String> categoryNames;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.supplierId,
    required this.categoryIds,
    required this.brandIds,
    required this.price,
    required this.stock,
    required this.rating,
    this.deletedAt,
    this.supplierName,
    this.brandNames = const [],
    this.categoryNames = const [],
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    int? supplierId,
    List<int>? categoryIds,
    List<int>? brandIds,
    double? price,
    int? stock,
    double? rating,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? supplierName,
    List<String>? brandNames,
    List<String>? categoryNames,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      supplierId: supplierId ?? this.supplierId,
      categoryIds: categoryIds ?? this.categoryIds,
      brandIds: brandIds ?? this.brandIds,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      supplierName: supplierName ?? this.supplierName,
      brandNames: brandNames ?? this.brandNames,
      categoryNames: categoryNames ?? this.categoryNames,
    );
  }

  /// Тело для POST/PUT (ids, не вложенные объекты).
  Map<String, dynamic> toWriteJson() => {
    'name': name,
    'sku': sku,
    'supplierId': supplierId,
    'categoryIds': categoryIds,
    'brandIds': brandIds,
    'price': price,
    'stock': stock,
    'rating': rating,
  };

  Map<String, dynamic> toJson() => {
    ...toWriteJson(),
    'id': id,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'];
    final supplierId =
        (json['supplierId'] as num?)?.toInt() ??
        (supplier is Map ? (supplier['id'] as num?)?.toInt() : null) ??
        0;

    final brands = json['brands'];
    final categories = json['categories'];

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      supplierId: supplierId,
      categoryIds: _ids(json['categoryIds'] ?? categories),
      brandIds: _ids(json['brandIds'] ?? brands),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      deletedAt:
          json['deletedAt'] == null
              ? null
              : DateTime.tryParse(json['deletedAt'].toString()),
      supplierName: supplier is Map ? supplier['name'] as String? : null,
      brandNames: _names(brands),
      categoryNames: _names(categories),
    );
  }

  static List<int> _ids(dynamic value) {
    if (value is List) {
      return value
          .map((e) {
            if (e is Map) return (e['id'] as num?)?.toInt() ?? 0;
            return (e as num).toInt();
          })
          .where((id) => id > 0)
          .toList();
    }
    if (value is num) return [value.toInt()];
    return const [];
  }

  static List<String> _names(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }
}
