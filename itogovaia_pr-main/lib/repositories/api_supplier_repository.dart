import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_session.dart';
import '../models/page_result.dart';
import '../models/supplier.dart';
import '../models/supplier_query.dart';
import 'supplier_repository.dart';

class ApiSupplierRepository implements SupplierRepository {
  ApiSupplierRepository(this._dio, this._auth);
  final Dio _dio;
  final AuthSession _auth;
  CancelToken? _findToken;

  @override
  Future<PageResult<Supplier>> find(SupplierQuery q) async {
    await _auth.ensureLibrarian();
    _findToken?.cancel('устаревший поиск');
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final response = await _dio.get(
        '/suppliers',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.country != null) 'country': q.country,
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        },
        cancelToken: token,
      );
      final data = response.data as Map<String, dynamic>;
      return PageResult(
        items:
            (data['items'] as List? ?? const [])
                .whereType<Map>()
                .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
        page: (data['page'] as num?)?.toInt() ?? q.page,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<Supplier?> findById(int id) async {
    await _auth.ensureLibrarian();
    try {
      return await guardRead(() async {
        final r = await _dio.get('/suppliers/$id');
        return Supplier.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Supplier>> findAll({bool includeDeleted = false}) async {
    final page = await find(
      SupplierQuery(size: 100, includeDeleted: includeDeleted),
    );
    return page.items;
  }

  @override
  Future<Supplier> create(Supplier supplier) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final body = {
        'name': supplier.name,
        'country': supplier.country,
        'contactPerson': supplier.contactPerson,
        'phone': supplier.phone,
        'email': supplier.email,
        'rating': supplier.rating,
      };
      final r = await _dio.post('/suppliers', data: body);
      return Supplier.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<Supplier> update(Supplier supplier) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final body = {
        'name': supplier.name,
        'country': supplier.country,
        'contactPerson': supplier.contactPerson,
        'phone': supplier.phone,
        'email': supplier.email,
        'rating': supplier.rating,
      };
      final r = await _dio.put('/suppliers/${supplier.id}', data: body);
      return Supplier.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await _auth.ensureLibrarian();
    await guard(() => _dio.delete('/suppliers/$id'));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _auth.ensureAdmin();
    await guard(
      () => _dio.delete('/suppliers/$id', queryParameters: {'hard': true}),
    );
  }

  @override
  Future<void> restore(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.post('/suppliers/$id/restore'));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final r = await _dio.post('/suppliers/bulk-delete', data: {'ids': ids});
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
}
