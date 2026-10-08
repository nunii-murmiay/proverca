import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';
import '../repositories/category_repository.dart';
import 'entity_list_notifier.dart';

class CategoryListNotifier
    extends EntityListNotifier<ProductCategory, CategoryQuery> {
  final CategoryRepository _repository;

  CategoryListNotifier(this._repository) : super(const CategoryQuery());

  @override
  Future<PageResult<ProductCategory>> fetch(CategoryQuery query) =>
      _repository.find(query);

  @override
  int idOf(ProductCategory item) => item.id;

  @override
  Future<void> doSoftDelete(int id) => _repository.softDelete(id);

  @override
  Future<void> doHardDelete(int id) => _repository.hardDelete(id);

  @override
  Future<void> doRestore(int id) => _repository.restore(id);

  @override
  Future<void> doDeleteMany(List<int> ids) => _repository.deleteMany(ids);

  @override
  Future<void> doRestoreMany(List<int> ids) => _repository.restoreMany(ids);
}
