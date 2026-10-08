import 'package:flutter/material.dart';

import '../models/product.dart';

Future<void> showProductViewDialog(
  BuildContext context, {
  required Product product,
  required String supplierName,
  required String categoriesLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pets, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(product.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Артикул', product.sku),
            _row('Цена', '${product.price.toStringAsFixed(0)} ₽'),
            _row('Количество', '${product.stock} шт.'),
            _row('Категории', categoriesLabel),
            _row('Поставщик', product.supplierName ?? supplierName),
            _row('Рейтинг', '★ ${product.rating}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );
    },
  );
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
