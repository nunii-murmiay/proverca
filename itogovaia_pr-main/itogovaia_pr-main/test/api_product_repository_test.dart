import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exceptions.dart';
import 'package:flutter_application_1/core/auth_session.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/models/product_query.dart';
import 'package:flutter_application_1/repositories/api_product_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late AuthSession auth;
  late ApiProductRepository repo;

  setUp(() {
    auth = AuthSession.fixed('test-token');
    dio = buildDio(tokenProvider: () => auth.accessToken);
    adapter = DioAdapter(
      dio: dio,
      matcher: const UrlRequestMatcher(),
    );
    repo = ApiProductRepository(dio, auth);
  });

  test('1. find разбирает страницу товаров с сервера', () async {
    adapter.onGet(
      '/products',
      (server) => server.reply(200, {
        'items': [
          {
            'id': 1,
            'name': 'Корм Premium',
            'sku': 'PET-100',
            'supplier': {'id': 2, 'name': 'ЗооОпт'},
            'brands': [
              {'id': 3, 'name': 'Royal Canin'}
            ],
            'categories': [
              {'id': 4, 'name': 'Корма'}
            ],
            'price': 1990,
            'stock': 8,
            'rating': 4.7,
            'deletedAt': null,
          }
        ],
        'page': 1,
        'size': 10,
        'total': 1,
      }),
    );

    final page = await repo.find(const ProductQuery());
    expect(page.total, 1);
    expect(page.items, hasLength(1));
    expect(page.items.first.name, 'Корм Premium');
    expect(page.items.first.supplierId, 2);
    expect(page.items.first.brandIds, [3]);
    expect(page.items.first.categoryIds, [4]);
  });

  test('2. create отправляет write-json и возвращает созданный объект', () async {
    adapter.onPost(
      '/products',
      (server) => server.reply(201, {
        'id': 42,
        'name': 'Игрушка',
        'sku': 'PET-42',
        'supplierId': 1,
        'brandIds': [1],
        'categoryIds': [2],
        'price': 500,
        'stock': 3,
        'rating': 4.0,
        'deletedAt': null,
      }),
      data: Matchers.any,
    );

    final created = await repo.create(
      const Product(
        id: 0,
        name: 'Игрушка',
        sku: 'PET-42',
        supplierId: 1,
        brandIds: [1],
        categoryIds: [2],
        price: 500,
        stock: 3,
        rating: 4.0,
      ),
    );
    expect(created.id, 42);
    expect(created.sku, 'PET-42');
  });

  test('3. ответ 422 превращается в ValidationException с ошибками полей', () async {
    adapter.onPost(
      '/products',
      (server) => server.reply(422, {
        'message': 'Ошибка валидации',
        'errors': {'sku': 'Товар с таким артикулом уже существует'},
      }),
      data: Matchers.any,
    );

    expect(
      () => repo.create(
        const Product(
          id: 0,
          name: 'Дубликат',
          sku: 'RC-MED-15KG',
          supplierId: 1,
          brandIds: [1],
          categoryIds: [1],
          price: 100,
          stock: 1,
          rating: 5,
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['sku'],
          'sku',
          contains('артикул'),
        ),
      ),
    );
  });

  test('4. недоступность сервера даёт NetworkException', () async {
    adapter.onGet(
      '/products',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    expect(
      () => repo.find(const ProductQuery()),
      throwsA(isA<NetworkException>()),
    );
  });

  test('5. findById при 404 возвращает null', () async {
    adapter.onGet(
      '/products/999',
      (server) => server.reply(404, {'message': 'Не найдено'}),
    );

    final found = await repo.findById(999);
    expect(found, isNull);
  });

  test('6. softDelete вызывает DELETE без hard', () async {
    adapter.onDelete(
      '/products/7',
      (server) => server.reply(204, null),
    );

    await repo.softDelete(7);
  });
}
