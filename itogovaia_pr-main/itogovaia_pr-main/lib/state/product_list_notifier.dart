import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/product_repository.dart';
import 'entity_list_notifier.dart';

export 'entity_list_notifier.dart' show LoadStatus;

class ProductListNotifier extends EntityListNotifier<Product, ProductQuery> {
  final ProductRepository _repository;

  ProductListNotifier(this._repository) : super(const ProductQuery());

  @override
  Future<PageResult<Product>> fetch(ProductQuery query) => _repository.find(query);

  @override
  int idOf(Product item) => item.id;

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
