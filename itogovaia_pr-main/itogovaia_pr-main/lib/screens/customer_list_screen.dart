import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../core/ui_errors.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../state/auth_notifier.dart';
import '../state/customer_list_notifier.dart';
import '../widgets/customer_card.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_load_body.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/responsive_chrome.dart';
import '../widgets/search_filter_bar.dart';

class CustomerListScreen extends StatefulWidget {
  final CustomerQuery initialQuery;
  const CustomerListScreen({super.key, required this.initialQuery});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant CustomerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CustomerListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _updateUrl(CustomerQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.cardLevel != null) params['level'] = q.cardLevel!;
    if (q.sortField != 'fullName') params['sort'] = q.sortField;
    if (!q.sortAscending) params['asc'] = 'false';
    if (q.page > 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/customers', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CustomerListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final canRestore = auth.can(AppOperation.restoreDeleted);
    final canHard = auth.can(AppOperation.hardDelete);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Клиенты')),
      floatingActionButton: ResponsiveAddButton(
        onPressed: () => context.go('/customers/new'),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Column(
          children: [
            ListToolbar(
              search: DebouncedSearchBar(
                initialValue: notifier.query.search,
                hintText: 'Поиск клиента...',
                onChanged: (t) =>
                    _updateUrl(notifier.query.copyWith(search: t)),
              ),
              filtersOpen: _showFilters,
              onToggleFilters: () =>
                  setState(() => _showFilters = !_showFilters),
              filtersPanel: CustomerFilterPanel(
                query: notifier.query,
                onQueryChanged: _updateUrl,
                onReset: () => _updateUrl(const CustomerQuery()),
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
    CustomerListNotifier notifier,
    bool isMobile, {
    required bool canRestore,
    required bool canHard,
  }) {
    return ListLoadBody(
      status: notifier.status,
      error: notifier.error,
      isEmpty: notifier.result.items.isEmpty,
      emptyMessage: 'Клиенты не найдены',
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
                          return CustomerCard(
                            customer: item,
                            isSelected: notifier.selected.contains(item.id),
                            onToggleSelect: notifier.toggleSelection,
                            onEdit: () =>
                                context.go('/customers/${item.id}/edit'),
                            onDelete: () => runGuarded(
                              context,
                              () => notifier.softDelete(item.id),
                            ),
                            onRestore: canRestore
                                ? () => runGuarded(
                                      context,
                                      () => notifier.restore(item.id),
                                    )
                                : null,
                          );
                        },
                      )
                    : EntityTable<Customer>(
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
                            label: 'ФИО',
                            sortField: 'fullName',
                            build: (c) => Text(c.fullName),
                          ),
                          TableColumnSpec(
                            label: 'Email',
                            sortField: 'email',
                            build: (c) => Text(c.email),
                          ),
                          TableColumnSpec(
                            label: 'Телефон',
                            build: (c) => Text(c.phone),
                          ),
                          TableColumnSpec(
                            label: 'Карта',
                            build: (c) => Text(c.card.number),
                          ),
                          TableColumnSpec(
                            label: 'Уровень',
                            sortField: 'level',
                            build: (c) => Text(c.card.level),
                          ),
                          TableColumnSpec(
                            label: 'Баллы',
                            sortField: 'points',
                            numeric: true,
                            build: (c) => Text('${c.card.points}'),
                          ),
                        ],
                        actions: (c) => [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                context.go('/customers/${c.id}/edit'),
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
                              onPressed: () => runGuarded(
                                context,
                                () => notifier.softDelete(c.id),
                              ),
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
