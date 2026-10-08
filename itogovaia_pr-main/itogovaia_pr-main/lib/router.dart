import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/permissions.dart';
import 'models/brand_query.dart';
import 'models/category_query.dart';
import 'models/customer_query.dart';
import 'models/product_query.dart';
import 'models/supplier_query.dart';
import 'screens/access_denied_screen.dart';
import 'screens/brand_form_screen.dart';
import 'screens/brand_list_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/customer_form_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_purchases_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/supplier_form_screen.dart';
import 'screens/supplier_list_screen.dart';
import 'screens/users_screen.dart';
import 'state/auth_notifier.dart';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/products',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.isRestoring) return null;

      final path = state.uri.path;
      return Permissions.redirectForPath(
        path: path,
        authenticated: auth.isAuthenticated,
        role: auth.user?.role,
      );
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/denied', builder: (_, __) => const AccessDeniedScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              return ProductListScreen(
                initialQuery: ProductQuery(
                  search: q['search'] ?? '',
                  categoryId: int.tryParse(q['categoryId'] ?? ''),
                  brandId: int.tryParse(q['brandId'] ?? ''),
                  supplierId: int.tryParse(q['supplierId'] ?? ''),
                  priceFrom: double.tryParse(q['priceFrom'] ?? ''),
                  priceTo: double.tryParse(q['priceTo'] ?? ''),
                  sortField: q['sort'] ?? 'name',
                  sortAscending: q['asc'] != 'false',
                  page: int.tryParse(q['page'] ?? '') ?? 1,
                  size: int.tryParse(q['size'] ?? '') ?? 10,
                  includeDeleted: q['includeDeleted'] == 'true',
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => ProductFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/my-purchases',
            builder: (_, __) => const MyPurchasesScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (_, __) => const SalesScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (_, __) => const StatsScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              return SupplierListScreen(
                initialQuery: SupplierQuery(
                  search: q['search'] ?? '',
                  country: q['country'],
                  sortField: q['sort'] ?? 'name',
                  sortAscending: q['asc'] != 'false',
                  page: int.tryParse(q['page'] ?? '') ?? 1,
                  size: int.tryParse(q['size'] ?? '') ?? 10,
                  includeDeleted: q['includeDeleted'] == 'true',
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const SupplierFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => SupplierFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/brands',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              return BrandListScreen(
                initialQuery: BrandQuery(
                  search: q['search'] ?? '',
                  sortField: q['sort'] ?? 'name',
                  sortAscending: q['asc'] != 'false',
                  page: int.tryParse(q['page'] ?? '') ?? 1,
                  size: int.tryParse(q['size'] ?? '') ?? 10,
                  includeDeleted: q['includeDeleted'] == 'true',
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const BrandFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => BrandFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              return CategoryListScreen(
                initialQuery: CategoryQuery(
                  search: q['search'] ?? '',
                  page: int.tryParse(q['page'] ?? '') ?? 1,
                  size: int.tryParse(q['size'] ?? '') ?? 10,
                  includeDeleted: q['includeDeleted'] == 'true',
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const CategoryFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => CategoryFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              return CustomerListScreen(
                initialQuery: CustomerQuery(
                  search: q['search'] ?? '',
                  cardLevel: q['level'],
                  sortField: q['sort'] ?? 'fullName',
                  sortAscending: q['asc'] != 'false',
                  page: int.tryParse(q['page'] ?? '') ?? 1,
                  size: int.tryParse(q['size'] ?? '') ?? 10,
                  includeDeleted: q['includeDeleted'] == 'true',
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => CustomerFormScreen(
                  id: int.tryParse(s.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool Function(AuthNotifier auth) visible;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.visible,
  });
}

class AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  static final _all = <_NavItem>[
    _NavItem(
      path: '/products',
      label: 'Товары',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      visible: (_) => true,
    ),
    _NavItem(
      path: '/my-purchases',
      label: 'Мои покупки',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      visible: (a) => a.can(AppOperation.viewOwnPurchases),
    ),
    _NavItem(
      path: '/sales',
      label: 'Продажи',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      visible: (a) => a.can(AppOperation.createSale),
    ),
    _NavItem(
      path: '/suppliers',
      label: 'Поставщики',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      visible: (a) => a.can(AppOperation.manageCatalog),
    ),
    _NavItem(
      path: '/brands',
      label: 'Бренды',
      icon: Icons.sell_outlined,
      selectedIcon: Icons.sell,
      visible: (a) => a.can(AppOperation.manageCatalog),
    ),
    _NavItem(
      path: '/categories',
      label: 'Категории',
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
      visible: (a) => a.can(AppOperation.manageCatalog),
    ),
    _NavItem(
      path: '/customers',
      label: 'Клиенты',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      visible: (a) => a.can(AppOperation.manageCustomers),
    ),
    _NavItem(
      path: '/users',
      label: 'Пользователи',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      visible: (a) => a.can(AppOperation.manageUsers),
    ),
    _NavItem(
      path: '/stats',
      label: 'Статистика',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      visible: (a) => a.can(AppOperation.viewStats),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final isNarrow = width < 600;

    final items = _all.where((n) => n.visible(auth)).toList();
    var index = items.indexWhere((n) => location.startsWith(n.path));
    if (index < 0) index = 0;

    final user = auth.user;
    final useBottomNav = !isWide && items.length <= 4;
    final useDrawer = !isWide && items.length > 4;

    return Scaffold(
      drawer: useDrawer
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    DrawerHeader(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          user == null
                              ? 'ЗооМаг'
                              : '${user.fullName}\n${user.role.label}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    for (final n in items)
                      ListTile(
                        leading: Icon(
                          location.startsWith(n.path) ? n.selectedIcon : n.icon,
                        ),
                        title: Text(n.label),
                        selected: location.startsWith(n.path),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(n.path);
                        },
                      ),
                  ],
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (useDrawer)
                      Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                    const Icon(Icons.pets, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user == null
                            ? 'ЗооМаг'
                            : '${user.fullName} · ${user.role.label}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Выйти',
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (isWide)
                  NavigationRail(
                    selectedIndex: index.clamp(0, items.length - 1),
                    onDestinationSelected: (i) => context.go(items[i].path),
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: const Icon(
                              Icons.pets,
                              size: 28,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ЗооМаг',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    destinations: [
                      for (final n in items)
                        NavigationRailDestination(
                          icon: Icon(n.icon),
                          selectedIcon: Icon(n.selectedIcon),
                          label: Text(n.label),
                        ),
                    ],
                  ),
                if (isWide) const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: useBottomNav
          ? NavigationBar(
              selectedIndex: index.clamp(0, items.length - 1),
              onDestinationSelected: (i) => context.go(items[i].path),
              labelBehavior: isNarrow
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              height: isNarrow ? 64 : 80,
              destinations: [
                for (final n in items)
                  NavigationDestination(
                    icon: Icon(n.icon),
                    selectedIcon: Icon(n.selectedIcon),
                    label: n.label,
                  ),
              ],
            )
          : null,
    );
  }
}
