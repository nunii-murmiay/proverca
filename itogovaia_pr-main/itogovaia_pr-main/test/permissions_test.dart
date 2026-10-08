import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/permissions.dart';
import 'package:flutter_application_1/models/role.dart';

void main() {
  group('Permissions.can — соответствие роли и операции', () {
    test('1. Покупатель видит каталог, но не управляет им', () {
      expect(Permissions.can(Role.reader, AppOperation.viewCatalog), isTrue);
      expect(Permissions.can(Role.reader, AppOperation.manageCatalog), isFalse);
    });

    test('2. Покупатель видит свои покупки; менеджер — нет (другой экран)', () {
      expect(
        Permissions.can(Role.reader, AppOperation.viewOwnPurchases),
        isTrue,
      );
      expect(
        Permissions.can(Role.librarian, AppOperation.viewOwnPurchases),
        isFalse,
      );
      expect(
        Permissions.can(Role.admin, AppOperation.viewOwnPurchases),
        isFalse,
      );
    });

    test('3. Менеджер оформляет продажи и ведёт клиентов', () {
      expect(Permissions.can(Role.librarian, AppOperation.createSale), isTrue);
      expect(
        Permissions.can(Role.librarian, AppOperation.manageCustomers),
        isTrue,
      );
      expect(Permissions.can(Role.reader, AppOperation.createSale), isFalse);
    });

    test('4. Только администратор: hard-delete, restore, пользователи, статистика', () {
      for (final op in [
        AppOperation.hardDelete,
        AppOperation.restoreDeleted,
        AppOperation.manageUsers,
        AppOperation.viewStats,
      ]) {
        expect(Permissions.can(Role.reader, op), isFalse, reason: '$op');
        expect(Permissions.can(Role.librarian, op), isFalse, reason: '$op');
        expect(Permissions.can(Role.admin, op), isTrue, reason: '$op');
      }
    });

    test('5. Администратор наследует права менеджера на каталог', () {
      expect(Permissions.can(Role.admin, AppOperation.manageCatalog), isTrue);
      expect(Permissions.can(Role.admin, AppOperation.createSale), isTrue);
    });
  });

  group('Permissions.redirectForPath', () {
    test('6. Гость уходит на /login с from=', () {
      final to = Permissions.redirectForPath(
        path: '/products',
        authenticated: false,
        role: null,
      );
      expect(to, '/login?from=%2Fproducts');
    });

    test('7. Покупатель не попадает на /users и /sales', () {
      expect(
        Permissions.redirectForPath(
          path: '/users',
          authenticated: true,
          role: Role.reader,
        ),
        '/denied',
      );
      expect(
        Permissions.redirectForPath(
          path: '/sales',
          authenticated: true,
          role: Role.reader,
        ),
        '/denied',
      );
    });

    test('8. Менеджер не попадает на /my-purchases и /stats', () {
      expect(
        Permissions.redirectForPath(
          path: '/my-purchases',
          authenticated: true,
          role: Role.librarian,
        ),
        '/denied',
      );
      expect(
        Permissions.redirectForPath(
          path: '/stats',
          authenticated: true,
          role: Role.librarian,
        ),
        '/denied',
      );
    });
  });
}
