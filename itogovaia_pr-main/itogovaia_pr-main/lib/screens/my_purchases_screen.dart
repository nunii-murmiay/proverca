import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/customer.dart';
import '../state/auth_notifier.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = context.read<Dio>();
      final user = context.read<AuthNotifier>().user;
      Customer? customer;
      if (user?.customerId != null) {
        final cData = await guard(() async {
          final r = await dio.get('/customers/${user!.customerId}');
          return Map<String, dynamic>.from(r.data as Map);
        });
        customer = Customer.fromJson(cData);
      }

      final data = await guard(() async {
        final r = await dio.get('/sales', queryParameters: {'size': 50});
        return r.data as Map<String, dynamic>;
      });
      var items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final cid = user?.customerId;
      if (cid != null) {
        items = items.where((s) {
          final top = (s['customerId'] as num?)?.toInt();
          final nested =
              (s['customer'] as Map?)?['id'] as num?;
          final saleCid = top ?? nested?.toInt();
          return saleCid == cid;
        }).toList();
      } else if (user != null) {
        items = [];
      }
      if (!mounted) return;
      setState(() {
        _customer = customer;
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _extendLoyaltyNote(Map<String, dynamic> sale) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Покупка #${sale['id']} учтена в программе лояльности.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final pad = narrow ? 12.0 : 16.0;
    final card = _customer?.card;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои покупки'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: EdgeInsets.all(pad),
                  children: [
                    Text(
                      'Покупатель: ${user?.fullName ?? '—'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text('Здесь показаны только ваши покупки.'),
                    if (card != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(narrow ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Карта лояльности',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text('Номер: ${card.number}'),
                              Text('Уровень: ${card.level}'),
                              Text('Баллы: ${card.points}'),
                              Text(
                                'Выдана: ${card.issuedAt.toLocal().toString().split('.').first}',
                              ),
                              if (_customer != null) ...[
                                const SizedBox(height: 4),
                                Text('Email: ${_customer!.email}'),
                                if (_customer!.phone.isNotEmpty)
                                  Text('Телефон: ${_customer!.phone}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'История покупок',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Покупок пока нет')),
                      )
                    else
                      ..._items.map((s) {
                        final product = s['product'] as Map<String, dynamic>?;
                        final name = product?['name']?.toString() ?? 'Товар';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: narrow,
                            leading: const Icon(Icons.receipt_long),
                            title: Text(name, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              'Кол-во: ${s['quantity']} · '
                              '${s['totalPrice']} ₽',
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: TextButton(
                              onPressed: () => _extendLoyaltyNote(s),
                              child: const Text('В лояльность'),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
