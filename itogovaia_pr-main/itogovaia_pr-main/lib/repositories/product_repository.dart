import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';

abstract interface class ProductRepository {
  Future<PageResult<Product>> find(ProductQuery query);
  Future<Product?> findById(int id);
  Future<List<Product>> findAll({bool includeDeleted = false});
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<bool> isSkuTaken(String sku, {int? excludeId});
  Future<int> countBySupplier(int supplierId, {bool includeDeleted = false});
  Future<int> countByBrand(int brandId, {bool includeDeleted = false});
  Future<int> countByCategory(int categoryId, {bool includeDeleted = false});
}
