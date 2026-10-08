import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_session.dart';
import '../models/brand.dart';
import '../models/brand_query.dart';
import '../models/page_result.dart';
import 'brand_repository.dart';

class ApiBrandRepository implements BrandRepository {
  ApiBrandRepository(this._dio, this._auth);
  final Dio _dio;
  final AuthSession _auth;
  CancelToken? _findToken;

  @override
  Future<PageResult<Brand>> find(BrandQuery q) async {
    await _auth.ensureLibrarian();
    _findToken?.cancel('устаревший поиск');
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final response = await _dio.get(
        '/brands',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.country != null) 'country': q.country,
          if (q.supplierId != null) 'supplierId': q.supplierId,
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
            .map((e) => Brand.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? q.page,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<Brand?> findById(int id) async {
    await _auth.ensureLibrarian();
    try {
      return await guardRead(() async {
        final r = await _dio.get('/brands/$id');
        return Brand.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Brand>> findAll({bool includeDeleted = false}) async {
    final page = await find(BrandQuery(size: 100, includeDeleted: includeDeleted));
    return page.items;
  }

  @override
  Future<Brand> create(Brand brand) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final r = await _dio.post('/brands', data: brand.toJson()..remove('id')..remove('deletedAt'));
      return Brand.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<Brand> update(Brand brand) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final body = brand.toJson()..remove('deletedAt');
      final r = await _dio.put('/brands/${brand.id}', data: body);
      return Brand.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await _auth.ensureLibrarian();
    await guard(() => _dio.delete('/brands/$id'));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.delete('/brands/$id', queryParameters: {'hard': true}));
  }

  @override
  Future<void> restore(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.post('/brands/$id/restore'));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final r = await _dio.post('/brands/bulk-delete', data: {'ids': ids});
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
