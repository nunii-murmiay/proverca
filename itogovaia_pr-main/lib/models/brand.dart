/// Бренд зоотоваров (аналог Author в учебной библиотеке).
class Brand {
  final int id;
  final String name;
  final String country;
  final String description;

  /// Поставщики, у которых доступен бренд — для каскадного отбора в форме товара.
  final List<int> supplierIds;
  final DateTime? deletedAt;

  const Brand({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.supplierIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Brand copyWith({
    int? id,
    String? name,
    String? country,
    String? description,
    List<int>? supplierIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      description: description ?? this.description,
      supplierIds: supplierIds ?? this.supplierIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'description': description,
    'supplierIds': supplierIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    description: json['description'] as String? ?? '',
    supplierIds:
        (json['supplierIds'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [],
    deletedAt:
        json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'].toString()),
  );
}
