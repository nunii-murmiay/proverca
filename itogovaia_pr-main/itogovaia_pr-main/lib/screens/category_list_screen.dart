import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../core/ui_errors.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../repositories/product_repository.dart';
import '../state/auth_notifier.dart';
import '../state/category_list_notifier.dart';
import '../widgets/category_card.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_load_body.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/responsive_chrome.dart';
import '../widgets/search_filter_bar.dart';

class CategoryListScreen extends StatefulWidget {
  final CategoryQuery initialQuery;
  const CategoryListScreen({super.key, required this.initialQuery});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant CategoryListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CategoryListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _updateUrl(CategoryQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.page > 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/categories', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  Future<void> _tryDelete(int id, String name) async {
    final count = await context.read<ProductRepository>().countByCategory(id);
    if (!mounted) return;
    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(
            'Нельзя удалить категорию «$name»: связана с $count товар(ами).',
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
    await context.read<CategoryListNotifier>().softDelete(id);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CategoryListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final canRestore = auth.can(AppOperation.restoreDeleted);
    final canHard = auth.can(AppOperation.hardDelete);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Категории')),
      floatingActionButton: ResponsiveAddButton(
        onPressed: () => context.go('/categories/new'),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Column(
          children: [
            ListToolbar(
              search: DebouncedSearchBar(
                initialValue: notifier.query.search,
                hintText: 'Поиск категории...',
                onChanged: (t) =>
                    _updateUrl(notifier.query.copyWith(search: t)),
              ),
              filtersOpen: _showFilters,
              onToggleFilters: () =>
                  setState(() => _showFilters = !_showFilters),
              filtersPanel: CategoryFilterPanel(
                query: notifier.query,
                onQueryChanged: _updateUrl,
                onReset: () => _updateUrl(const CategoryQuery()),
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
    CategoryListNotifier notifier,
    bool isMobile, {
    required bool canRestore,
    required bool canHard,
  }) {
    return ListLoadBody(
      status: notifier.status,
      error: notifier.error,
      isEmpty: notifier.result.items.isEmpty,
      emptyMessage: 'Категории не найдены',
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
                          return CategoryCard(
                            category: item,
                            isSelected: notifier.selected.contains(item.id),
                            onToggleSelect: notifier.toggleSelection,
                            onEdit: () =>
                                context.go('/categories/${item.id}/edit'),
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
                    : EntityTable<ProductCategory>(
                        items: items,
                        idOf: (c) => c.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        onToggleSelectAll: () => notifier.toggleSelectAll(
                          items.map((c) => c.id).toList(),
                        ),
                        sortField: notifier.query.sortField,
                        sortAscending: notifier.query.sortAscending,
                        isDeletedOf: (c) => c.isDeleted,
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
                            build: (c) => Text(c.name),
                          ),
                          TableColumnSpec(
                            label: 'Описание',
                            build: (c) => Text(c.description),
                          ),
                          TableColumnSpec(
                            label: 'Иконка',
                            build: (c) => Text(c.iconName),
                          ),
                        ],
                        actions: (c) => [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                context.go('/categories/${c.id}/edit'),
                          ),
                          if (c.isDeleted) ...[
                            if (canRestore)
                              IconButton(
                                icon: const Icon(Icons.restore, size: 18),
                                onPressed: () => runGuarded(
                                  context,
                                  () => notifier.restore(c.id),
                                ),
                              ),
                            if (canHard)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, size: 18),
                                color: Colors.red,
                                tooltip: 'Удалить навсегда',
                                onPressed: () => runGuarded(
                                  context,
                                  () => notifier.hardDelete(c.id),
                                ),
                              ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _tryDelete(c.id, c.name),
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
