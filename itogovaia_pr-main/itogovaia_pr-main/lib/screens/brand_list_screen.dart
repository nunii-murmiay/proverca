import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../core/ui_errors.dart';
import '../models/brand.dart';
import '../models/brand_query.dart';
import '../repositories/product_repository.dart';
import '../state/auth_notifier.dart';
import '../state/brand_list_notifier.dart';
import '../widgets/brand_card.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_load_body.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/responsive_chrome.dart';
import '../widgets/search_filter_bar.dart';

class BrandListScreen extends StatefulWidget {
  final BrandQuery initialQuery;
  const BrandListScreen({super.key, required this.initialQuery});

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant BrandListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BrandListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _updateUrl(BrandQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.sortField != 'name') params['sort'] = q.sortField;
    if (!q.sortAscending) params['asc'] = 'false';
    if (q.page > 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/brands', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  Future<void> _tryDelete(int id, String name) async {
    final count = await context.read<ProductRepository>().countByBrand(id);
    if (!mounted) return;
    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(
            'Нельзя удалить бренд «$name»: связан с $count товар(ами).',
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
    await context.read<BrandListNotifier>().softDelete(id);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BrandListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final canRestore = auth.can(AppOperation.restoreDeleted);
    final canHard = auth.can(AppOperation.hardDelete);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Бренды')),
      floatingActionButton: ResponsiveAddButton(
        onPressed: () => context.go('/brands/new'),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Column(
          children: [
            ListToolbar(
              search: DebouncedSearchBar(
                initialValue: notifier.query.search,
                hintText: 'Поиск бренда...',
                onChanged: (t) =>
                    _updateUrl(notifier.query.copyWith(search: t)),
              ),
              filtersOpen: _showFilters,
              onToggleFilters: () =>
                  setState(() => _showFilters = !_showFilters),
              filtersPanel: BrandFilterPanel(
                query: notifier.query,
                onQueryChanged: _updateUrl,
                onReset: () => _updateUrl(const BrandQuery()),
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
    BrandListNotifier notifier,
    bool isMobile, {
    required bool canRestore,
    required bool canHard,
  }) {
    return ListLoadBody(
      status: notifier.status,
      error: notifier.error,
      isEmpty: notifier.result.items.isEmpty,
      emptyMessage: 'Бренды не найдены',
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
                          return BrandCard(
                            brand: item,
                            isSelected: notifier.selected.contains(item.id),
                            onToggleSelect: notifier.toggleSelection,
                            onEdit: () =>
                                context.go('/brands/${item.id}/edit'),
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
                    : EntityTable<Brand>(
                        items: items,
                        idOf: (b) => b.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        onToggleSelectAll: () => notifier.toggleSelectAll(
                          items.map((b) => b.id).toList(),
                        ),
                        sortField: notifier.query.sortField,
                        sortAscending: notifier.query.sortAscending,
                        isDeletedOf: (b) => b.isDeleted,
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
                            build: (b) => Text(b.name),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (b) => Text(b.country),
                          ),
                          TableColumnSpec(
                            label: 'Описание',
                            build: (b) => Text(b.description),
                          ),
                        ],
                        actions: (b) => [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                context.go('/brands/${b.id}/edit'),
                          ),
                          if (b.isDeleted) ...[
                            if (canRestore)
                              IconButton(
                                icon: const Icon(Icons.restore, size: 18),
                                onPressed: () => runGuarded(
                                  context,
                                  () => notifier.restore(b.id),
                                ),
                              ),
                            if (canHard)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, size: 18),
                                color: Colors.red,
                                tooltip: 'Удалить навсегда',
                                onPressed: () => runGuarded(
                                  context,
                                  () => notifier.hardDelete(b.id),
                                ),
                              ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _tryDelete(b.id, b.name),
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
