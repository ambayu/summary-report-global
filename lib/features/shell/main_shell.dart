import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/enums.dart';
import '../../shared/widgets/brand_avatar.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(authRepositoryProvider).currentSession;
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: settingsRepo.listenable,
      builder: (context, box, child) {
        final settings = settingsRepo.settings;
        final brandName = settings.cafeName;
        final roleKey = session?.roleKey;
        final rootDestinations = _buildRootDestinations(settings, roleKey);
        final safeDestinations = rootDestinations.isEmpty
            ? const [
                _ShellDestination(
                  branchIndex: 0,
                  label: 'Dashboard',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  permission: AppPermission.dashboard,
                ),
              ]
            : rootDestinations;
        final selectedNavIndex = rootDestinations.indexWhere(
          (item) => item.branchIndex == navigationShell.currentIndex,
        );
        final visibleNavIndex = selectedNavIndex < 0 ? 0 : selectedNavIndex;
        final appBarTitle = safeDestinations
            .firstWhere(
              (item) => item.branchIndex == navigationShell.currentIndex,
              orElse: () => safeDestinations.first,
            )
            .label;

        return Scaffold(
          appBar: AppBar(
            title: Text('$brandName - $appBarTitle'),
            actions: [
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person,
                    size: 18,
                    color: AppColors.primaryRed,
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'home') {
                    context.go(RouteNames.dashboard);
                  } else if (value == 'profile') {
                    context.push(RouteNames.profil);
                  } else if (value == 'manage-roles') {
                    context.push(RouteNames.manageRoles);
                  } else if (value == 'manage-users') {
                    context.push(RouteNames.manageUsers);
                  } else if (value == 'settings') {
                    context.push(RouteNames.pengaturan);
                  } else if (value == 'logout') {
                    await ref.read(authRepositoryProvider).logout();
                    if (context.mounted) {
                      context.go(RouteNames.login);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'home',
                    child: Text('Halaman Utama'),
                  ),
                  const PopupMenuItem(value: 'profile', child: Text('Profil')),
                  if (roleKey != null &&
                      settings.hasPermission(
                        roleKey,
                        AppPermission.manageUsers,
                      ))
                    const PopupMenuItem(
                      value: 'manage-roles',
                      child: Text('Manajemen Role'),
                    ),
                  if (roleKey != null &&
                      settings.hasPermission(
                        roleKey,
                        AppPermission.manageUsers,
                      ))
                    const PopupMenuItem(
                      value: 'manage-users',
                      child: Text('Manajemen Pengguna'),
                    ),
                  if (roleKey != null &&
                      settings.hasPermission(roleKey, AppPermission.pengaturan))
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Pengaturan'),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryRed, AppColors.primaryDark],
                    ),
                  ),
                  currentAccountPicture: BrandAvatar(
                    brandName: brandName,
                    logoBase64: settings.logoBase64,
                  ),
                  accountName: Text(brandName),
                  accountEmail: Text(
                    '${session?.name ?? 'Guest'} - ${session?.roleLabel ?? 'Belum login'}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  onTap: () => context.go(RouteNames.dashboard),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Transaksi'),
                  onTap: () => context.go(RouteNames.transaksi),
                ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.riwayat))
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Riwayat'),
                    onTap: () => context.go(RouteNames.riwayat),
                  ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.laporan))
                  ListTile(
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: const Text('Laporan'),
                    onTap: () => context.go(RouteNames.laporan),
                  ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.produk))
                  ListTile(
                    leading: const Icon(Icons.local_cafe_outlined),
                    title: const Text('Menu Produk'),
                    onTap: () => context.push(RouteNames.produk),
                  ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.pelanggan))
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text('Pelanggan'),
                    onTap: () => context.push(RouteNames.pelanggan),
                  ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.pengeluaran))
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Pengeluaran'),
                    onTap: () => context.push(RouteNames.pengeluaran),
                  ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.manageUsers))
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Manajemen Role'),
                    onTap: () => context.push(RouteNames.manageRoles),
                  ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.manageUsers))
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Manajemen Pengguna'),
                    onTap: () => context.push(RouteNames.manageUsers),
                  ),
                if (roleKey != null &&
                    settings.hasPermission(roleKey, AppPermission.pengaturan))
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Pengaturan'),
                    onTap: () => context.push(RouteNames.pengaturan),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).logout();
                    if (context.mounted) {
                      context.go(RouteNames.login);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: visibleNavIndex,
            onDestinationSelected: (index) {
              final target = safeDestinations[index];
              navigationShell.goBranch(
                target.branchIndex,
                initialLocation:
                    target.branchIndex == navigationShell.currentIndex,
              );
            },
            destinations: safeDestinations
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  List<_ShellDestination> _buildRootDestinations(
    dynamic settings,
    String? roleKey,
  ) {
    final destinations = <_ShellDestination>[
      const _ShellDestination(
        branchIndex: 0,
        label: 'Dashboard',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        permission: AppPermission.dashboard,
      ),
      const _ShellDestination(
        branchIndex: 1,
        label: 'Transaksi',
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        permission: AppPermission.transaksi,
      ),
      const _ShellDestination(
        branchIndex: 2,
        label: 'Riwayat',
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        permission: AppPermission.riwayat,
      ),
      const _ShellDestination(
        branchIndex: 3,
        label: 'Laporan',
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        permission: AppPermission.laporan,
      ),
    ];

    return destinations.where((item) {
      return settings.hasPermission(roleKey, item.permission);
    }).toList();
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.permission,
  });

  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final AppPermission permission;
}
