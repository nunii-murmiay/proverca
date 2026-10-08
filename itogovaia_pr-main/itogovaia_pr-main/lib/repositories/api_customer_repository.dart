import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_session.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/page_result.dart';
import 'customer_repository.dart';

class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository(this._dio, this._auth);
  final Dio _dio;
  final AuthSession _auth;
  CancelToken? _findToken;

  @override
  Future<PageResult<Customer>> find(CustomerQuery q) async {
    await _auth.ensureLibrarian();
    _findToken?.cancel('устаревший поиск');
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final response = await _dio.get(
        '/customers',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.cardLevel != null) 'cardLevel': q.cardLevel,
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        },
        cancelToken: token,
      );
      final data = response.data as Map<String, dynamic>;
      return PageResult(
        items: (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? q.page,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<Customer?> findById(int id) async {
    await _auth.ensureLibrarian();
    try {
      return await guardRead(() async {
        final r = await _dio.get('/customers/$id');
        return Customer.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Customer>> findAll({bool includeDeleted = false}) async {
    final page =
        await find(CustomerQuery(size: 100, includeDeleted: includeDeleted));
    return page.items;
  }

  Map<String, dynamic> _body(Customer c) => {
        'fullName': c.fullName,
        'email': c.email,
        'phone': c.phone,
        'card': {
          'number': c.card.number,
          'issuedAt': c.card.issuedAt.toIso8601String(),
          'points': c.card.points,
          'level': c.card.level,
        },
      };

  @override
  Future<Customer> create(Customer customer) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final r = await _dio.post('/customers', data: _body(customer));
      return Customer.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<Customer> update(Customer customer) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final r = await _dio.put('/customers/${customer.id}', data: _body(customer));
      return Customer.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await _auth.ensureLibrarian();
    await guard(() => _dio.delete('/customers/$id'));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.delete('/customers/$id', queryParameters: {'hard': true}));
  }

  @override
  Future<void> restore(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.post('/customers/$id/restore'));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final r = await _dio.post('/customers/bulk-delete', data: {'ids': ids});
      return (r.data as Map)['deleted'] as int? ?? 0;
    });
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var n = 0;
    for (final id in ids) {
      await restore(id);
      n++;
    }
    return n;
  }

  @override
  Future<bool> isEmailTaken(String email, {int? excludeId}) async {
    final page = await find(CustomerQuery(search: email.trim(), size: 50));
    final needle = email.trim().toLowerCase();
    return page.items.any(
      (c) =>
          c.email.toLowerCase() == needle &&
          (excludeId == null || c.id != excludeId),
    );
  }
}

/// Для продажи с конфликтом 409 (демо п.10).
class ApiSalesRepository {
  ApiSalesRepository(this._dio, this._auth);
  final Dio _dio;
  final AuthSession _auth;

  Future<void> createSale({
    required int customerId,
    required int productId,
    required int quantity,
  }) async {
    await _auth.ensureLibrarian();
    await guard(() => _dio.post('/sales', data: {
          'customerId': customerId,
          'productId': productId,
          'quantity': quantity,
        }));
  }
}
