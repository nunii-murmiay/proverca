import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../repositories/api_customer_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/product_repository.dart';

class _CartLine {
  int? productId;
  final TextEditingController qty;

  _CartLine({this.productId, String qtyText = '1'})
      : qty = TextEditingController(text: qtyText);

  void dispose() => qty.dispose();
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sales = [];
  List<Customer> _customers = [];
  List<Product> _products = [];
  int? _customerId;
  final List<_CartLine> _lines = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lines.add(_CartLine());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() {
      final id = _products.isNotEmpty ? _products.first.id : null;
      _lines.add(_CartLine(productId: id));
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = context.read<Dio>();
      final customerRepo = context.read<CustomerRepository>();
      final productRepo = context.read<ProductRepository>();
      final customers = await customerRepo.findAll();
      final products = await productRepo.findAll();
      final data = await guard(() async {
        final r = await dio.get('/sales', queryParameters: {'size': 50});
        return r.data as Map<String, dynamic>;
      });
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _products = products;
        _sales = (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (_customerId == null ||
            customers.every((c) => c.id != _customerId)) {
          _customerId = customers.isNotEmpty ? customers.first.id : null;
        }
        for (final line in _lines) {
          if (line.productId == null ||
              products.every((p) => p.id != line.productId)) {
            line.productId = products.isNotEmpty ? products.first.id : null;
          }
        }
        _loading = false;
      });
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('403: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _createSale() async {
    if (_customerId == null) return;

    final toSubmit = <({int productId, int quantity})>[];
    for (final line in _lines) {
      if (line.productId == null) continue;
      final qty = int.tryParse(line.qty.text.trim()) ?? 0;
      if (qty < 1) continue;
      toSubmit.add((productId: line.productId!, quantity: qty));
    }

    if (toSubmit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один товар с количеством ≥ 1')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<ApiSalesRepository>();
      for (final row in toSubmit) {
        await repo.createSale(
          customerId: _customerId!,
          productId: row.productId,
          quantity: row.quantity,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            toSubmit.length == 1
                ? 'Продажа оформлена'
                : 'Оформлено позиций: ${toSubmit.length}',
          ),
        ),
      );
      for (final line in _lines) {
        line.qty.text = '1';
      }
      await _load();
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('403: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final pad = narrow ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Продажи'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(pad),
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(narrow ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Оформить продажу',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              // ignore: deprecated_member_use
                              value: _customerId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Клиент',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _customers
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.fullName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _customerId = v),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Товары в чеке',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_lines.length, (i) {
                              final line = _lines[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<int>(
                                            // ignore: deprecated_member_use
                                            value: line.productId,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              labelText: 'Товар ${i + 1}',
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            items: _products
                                                .map(
                                                  (p) => DropdownMenuItem(
                                                    value: p.id,
                                                    child: Text(
                                                      '${p.name} (склад: ${p.stock})',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (v) => setState(
                                              () => line.productId = v,
                                            ),
                                          ),
                                        ),
                                        if (_lines.length > 1) ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Убрать строку',
                                            onPressed: () => _removeLine(i),
                                            icon: const Icon(Icons.close),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: line.qty,
                                      decoration: const InputDecoration(
                                        labelText: 'Количество',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            OutlinedButton.icon(
                              onPressed: _products.isEmpty ? null : _addLine,
                              icon: const Icon(Icons.add),
                              label: const Text('Добавить товар'),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _saving ? null : _createSale,
                              icon: const Icon(Icons.point_of_sale),
                              label: const Text('Оформить чек'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Все продажи',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._sales.map((s) {
                      final product = s['product'] as Map<String, dynamic>?;
                      final customer = s['customer'] as Map<String, dynamic>?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: narrow,
                          title: Text(
                            product?['name']?.toString() ?? 'Товар',
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${customer?['fullName'] ?? 'Клиент'} · '
                            '×${s['quantity']} · ${s['totalPrice']} ₽',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
