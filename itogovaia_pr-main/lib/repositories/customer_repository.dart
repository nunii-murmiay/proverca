import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/page_result.dart';

abstract interface class CustomerRepository {
  Future<PageResult<Customer>> find(CustomerQuery query);
  Future<Customer?> findById(int id);
  Future<List<Customer>> findAll({bool includeDeleted = false});
  Future<Customer> create(Customer customer);
  Future<Customer> update(Customer customer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<bool> isEmailTaken(String email, {int? excludeId});
}
