import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_session.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';
import 'category_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._dio, this._auth);
  final Dio _dio;
  final AuthSession _auth;
  CancelToken? _findToken;

  @override
  Future<PageResult<ProductCategory>> find(CategoryQuery q) async {
    await _auth.ensureLibrarian();
    _findToken?.cancel('устаревший поиск');
    _findToken = CancelToken();
    final token = _findToken!;
    return guardRead(() async {
      final response = await _dio.get(
        '/categories',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
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
            .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? q.page,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<ProductCategory?> findById(int id) async {
    await _auth.ensureLibrarian();
    try {
      return await guardRead(() async {
        final r = await _dio.get('/categories/$id');
        return ProductCategory.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<ProductCategory>> findAll({bool includeDeleted = false}) async {
    final page =
        await find(CategoryQuery(size: 100, includeDeleted: includeDeleted));
    return page.items;
  }

  @override
  Future<ProductCategory> create(ProductCategory category) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final body = {
        'name': category.name,
        'description': category.description,
        'iconName': category.iconName,
      };
      final r = await _dio.post('/categories', data: body);
      return ProductCategory.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<ProductCategory> update(ProductCategory category) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final body = {
        'name': category.name,
        'description': category.description,
        'iconName': category.iconName,
      };
      final r = await _dio.put('/categories/${category.id}', data: body);
      return ProductCategory.fromJson(Map<String, dynamic>.from(r.data as Map));
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await _auth.ensureLibrarian();
    await guard(() => _dio.delete('/categories/$id'));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.delete('/categories/$id', queryParameters: {'hard': true}));
  }

  @override
  Future<void> restore(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.post('/categories/$id/restore'));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final r = await _dio.post('/categories/bulk-delete', data: {'ids': ids});
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
