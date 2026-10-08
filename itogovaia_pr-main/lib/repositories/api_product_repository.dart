import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_session.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._dio, this._auth);

  final Dio _dio;
  final AuthSession _auth;
  CancelToken? _findToken;

  Map<String, dynamic> _queryParams(ProductQuery q) => {
    if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
    if (q.categoryId != null) 'categoryId': q.categoryId,
    if (q.brandId != null) 'brandId': q.brandId,
    if (q.supplierId != null) 'supplierId': q.supplierId,
    if (q.priceFrom != null) 'priceFrom': q.priceFrom,
    if (q.priceTo != null) 'priceTo': q.priceTo,
    'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
    'page': q.page,
    'size': q.size,
    if (q.includeDeleted) 'includeDeleted': true,
  };

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await _auth.ensureLibrarian();
    _findToken?.cancel('устаревший поиск');
    _findToken = CancelToken();
    final token = _findToken!;

    return guardRead(() async {
      final response = await _dio.get(
        '/products',
        queryParameters: _queryParams(q),
        cancelToken: token,
      );
      final data = response.data as Map<String, dynamic>;
      return PageResult(
        items:
            (data['items'] as List? ?? const [])
                .whereType<Map>()
                .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
        page: (data['page'] as num?)?.toInt() ?? q.page,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<Product?> findById(int id) async {
    await _auth.ensureLibrarian();
    try {
      return await guardRead(() async {
        final response = await _dio.get('/products/$id');
        return Product.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Product>> findAll({bool includeDeleted = false}) async {
    final page = await find(
      ProductQuery(size: 100, includeDeleted: includeDeleted),
    );
    return page.items;
  }

  @override
  Future<Product> create(Product product) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final response = await _dio.post(
        '/products',
        data: product.toWriteJson(),
      );
      return Product.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  @override
  Future<Product> update(Product product) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final response = await _dio.put(
        '/products/${product.id}',
        data: product.toWriteJson(),
      );
      return Product.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await _auth.ensureLibrarian();
    await guard(() => _dio.delete('/products/$id'));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _auth.ensureAdmin();
    await guard(
      () => _dio.delete('/products/$id', queryParameters: {'hard': true}),
    );
  }

  @override
  Future<void> restore(int id) async {
    await _auth.ensureAdmin();
    await guard(() => _dio.post('/products/$id/restore'));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _auth.ensureLibrarian();
    return guard(() async {
      final response = await _dio.post(
        '/products/bulk-delete',
        data: {'ids': ids},
      );
      return (response.data as Map)['deleted'] as int? ?? 0;
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
  Future<bool> isSkuTaken(String sku, {int? excludeId}) async {
    final page = await find(ProductQuery(search: sku.trim(), size: 50));
    final needle = sku.trim().toUpperCase();
    return page.items.any(
      (p) =>
          p.sku.toUpperCase() == needle &&
          (excludeId == null || p.id != excludeId),
    );
  }

  @override
  Future<int> countBySupplier(
    int supplierId, {
    bool includeDeleted = false,
  }) async {
    final page = await find(
      ProductQuery(
        supplierId: supplierId,
        size: 1,
        includeDeleted: includeDeleted,
      ),
    );
    return page.total;
  }

  @override
  Future<int> countByBrand(int brandId, {bool includeDeleted = false}) async {
    final page = await find(
      ProductQuery(brandId: brandId, size: 1, includeDeleted: includeDeleted),
    );
    return page.total;
  }

  @override
  Future<int> countByCategory(
    int categoryId, {
    bool includeDeleted = false,
  }) async {
    final page = await find(
      ProductQuery(
        categoryId: categoryId,
        size: 1,
        includeDeleted: includeDeleted,
      ),
    );
    return page.total;
  }
}
