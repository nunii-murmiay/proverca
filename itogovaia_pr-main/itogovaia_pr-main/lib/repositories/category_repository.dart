import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';

abstract interface class CategoryRepository {
  Future<PageResult<ProductCategory>> find(CategoryQuery query);
  Future<ProductCategory?> findById(int id);
  Future<List<ProductCategory>> findAll({bool includeDeleted = false});
  Future<ProductCategory> create(ProductCategory category);
  Future<ProductCategory> update(ProductCategory category);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
}
