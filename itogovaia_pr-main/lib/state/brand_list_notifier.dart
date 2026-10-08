import '../models/brand.dart';
import '../models/brand_query.dart';
import '../models/page_result.dart';
import '../repositories/brand_repository.dart';
import 'entity_list_notifier.dart';

class BrandListNotifier extends EntityListNotifier<Brand, BrandQuery> {
  final BrandRepository _repository;

  BrandListNotifier(this._repository) : super(const BrandQuery());

  @override
  Future<PageResult<Brand>> fetch(BrandQuery query) => _repository.find(query);

  @override
  int idOf(Brand item) => item.id;

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
