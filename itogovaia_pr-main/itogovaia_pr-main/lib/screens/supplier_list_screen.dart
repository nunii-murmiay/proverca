import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../core/ui_errors.dart';
import '../models/supplier.dart';
import '../models/supplier_query.dart';
import '../repositories/product_repository.dart';
import '../state/auth_notifier.dart';
import '../state/supplier_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_load_body.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/responsive_chrome.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/supplier_card.dart';

class SupplierListScreen extends StatefulWidget {
  final SupplierQuery initialQuery;
  const SupplierListScreen({super.key, required this.initialQuery});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant SupplierListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SupplierListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _updateUrl(SupplierQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.country != null && q.country!.isNotEmpty) {
      params['country'] = q.country!;
    }
    if (q.sortField != 'name') params['sort'] = q.sortField;
    if (!q.sortAscending) params['asc'] = 'false';
    if (q.page > 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/suppliers', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  Future<void> _tryDelete(int id, String name) async {
    try {
      final count = await context.read<ProductRepository>().countBySupplier(id);
      if (!mounted) return;
      if (count > 0) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Удаление невозможно'),
            content: Text(
              'Нельзя удалить поставщика «$name»: на него ссылаются $count товар(ов).',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Понятно'),
              ),
            ],
          ),
        );
        return;
      }
      await context.read<SupplierListNotifier>().softDelete(id);
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SupplierListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final canRestore = auth.can(AppOperation.restoreDeleted);
    final canHard = auth.can(AppOperation.hardDelete);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Поставщики')),
      floatingActionButton: ResponsiveAddButton(
        onPressed: () => context.go('/suppliers/new'),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Column(
          children: [
            ListToolbar(
              search: DebouncedSearchBar(
                initialValue: notifier.query.search,
                hintText: 'Поиск поставщика...',
                onChanged: (t) =>
                    _updateUrl(notifier.query.copyWith(search: t)),
              ),
              filtersOpen: _showFilters,
              onToggleFilters: () =>
                  setState(() => _showFilters = !_showFilters),
              filtersPanel: SupplierFilterPanel(
                query: notifier.query,
                onQueryChanged: _updateUrl,
                onReset: () => _updateUrl(const SupplierQuery()),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _content(
                notifier,
                isMobile,
                canRestore: canRestore,
                canHard: canHard,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    SupplierListNotifier notifier,
    bool isMobile, {
    required bool canRestore,
    required bool canHard,
  }) {
    return ListLoadBody(
      status: notifier.status,
      error: notifier.error,
      isEmpty: notifier.result.items.isEmpty,
      emptyMessage: 'Поставщики не найдены',
      onRetry: () => notifier.load(),
      child: Builder(
        builder: (context) {
          final items = notifier.result.items;
          return Column(
            children: [
              Expanded(
                child: isMobile
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return SupplierCard(
                            supplier: item,
                            isSelected: notifier.selected.contains(item.id),
                            onToggleSelect: notifier.toggleSelection,
                            onEdit: () =>
                                context.go('/suppliers/${item.id}/edit'),
                            onDelete: () => _tryDelete(item.id, item.name),
                            onRestore: canRestore
                                ? () => runGuarded(
                                      context,
                                      () => notifier.restore(item.id),
                                    )
                                : null,
                          );
                        },
                      )
                    : EntityTable<Supplier>(
                        items: items,
                        idOf: (s) => s.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        onToggleSelectAll: () => notifier.toggleSelectAll(
                          items.map((s) => s.id).toList(),
                        ),
                        sortField: notifier.query.sortField,
                        sortAscending: notifier.query.sortAscending,
                        isDeletedOf: (s) => s.isDeleted,
                        onSort: (f) => _updateUrl(
                          notifier.query.copyWith(
                            sortField: f,
                            sortAscending: f == notifier.query.sortField
                                ? !notifier.query.sortAscending
                                : true,
                          ),
                        ),
                        columns: [
                          TableColumnSpec(
                            label: 'Название',
                            sortField: 'name',
                            build: (s) => Text(s.name),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (s) => Text(s.country),
                          ),
                          TableColumnSpec(
                            label: 'Контакт',
                            build: (s) => Text(s.contactPerson),
                          ),
                          TableColumnSpec(
                            label: 'Email',
                            build: (s) => Text(s.email),
                          ),
                          TableColumnSpec(
                            label: 'Рейтинг',
                            sortField: 'rating',
                            numeric: true,
                            build: (s) => Text('${s.rating}'),
                          ),
                        ],
                        actions: (s) => [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                context.go('/suppliers/${s.id}/edit'),
                          ),
                          if (s.isDeleted) ...[
                            if (canRestore)
                              IconButton(
                                icon: const Icon(Icons.restore, size: 18),
                                onPressed: () => runGuarded(
                                  context,
                                  () => notifier.restore(s.id),
                                ),
                              ),
                            if (canHard)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, size: 18),
                                color: Colors.red,
                                onPressed: () => runGuarded(
                                  context,
                                  () => notifier.hardDelete(s.id),
                                ),
                              ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _tryDelete(s.id, s.name),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              PaginationBar(
                page: notifier.result.page,
                size: notifier.result.size,
                totalPages: notifier.result.totalPages,
                totalItems: notifier.result.total,
                hasPrevious: notifier.result.hasPrevious,
                hasNext: notifier.result.hasNext,
                onPageChanged: (p) =>
                    _updateUrl(notifier.query.copyWith(page: p)),
                onSizeChanged: (s) =>
                    _updateUrl(notifier.query.copyWith(size: s, page: 1)),
              ),
            ],
          );
        },
      ),
    );
  }
}
