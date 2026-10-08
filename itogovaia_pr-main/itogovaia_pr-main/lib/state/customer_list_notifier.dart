import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/page_result.dart';
import '../repositories/customer_repository.dart';
import 'entity_list_notifier.dart';

class CustomerListNotifier extends EntityListNotifier<Customer, CustomerQuery> {
  final CustomerRepository _repository;

  CustomerListNotifier(this._repository) : super(const CustomerQuery());

  @override
  Future<PageResult<Customer>> fetch(CustomerQuery query) =>
      _repository.find(query);

  @override
  int idOf(Customer item) => item.id;

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
