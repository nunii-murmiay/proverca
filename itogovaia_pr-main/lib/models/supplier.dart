/// Поставщик (аналог Publisher — связь один ко многим с товарами).
class Supplier {
  final int id;
  final String name;
  final String country;
  final String contactPerson;
  final String phone;
  final String email;
  final double rating;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.name,
    required this.country,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.rating,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Supplier copyWith({
    int? id,
    String? name,
    String? country,
    String? contactPerson,
    String? phone,
    String? email,
    double? rating,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'rating': rating,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    contactPerson: json['contactPerson'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    deletedAt:
        json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'].toString()),
  );
}
