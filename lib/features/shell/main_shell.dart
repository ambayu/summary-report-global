import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/enums.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(authRepositoryProvider).currentSession;

    final titles = ['Dashboard', 'Transaksi', 'Riwayat', 'Laporan'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[navigationShell.currentIndex]),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryRed.withOpacity(0.12),
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
              } else if (value == 'settings') {
                context.push(RouteNames.pengaturan);
              } else if (value == 'logout') {
                await ref.read(authRepositoryProvider).logout();
                if (context.mounted) {
                  context.go(RouteNames.login);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'home', child: Text('Halaman Utama')),
              PopupMenuItem(value: 'profile', child: Text('Profil')),
              PopupMenuItem(value: 'settings', child: Text('Pengaturan')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.primaryDark],
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              accountName: Text(session?.name ?? 'Guest'),
              accountEmail: Text(session?.role.label ?? 'Belum login'),
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
            ListTile(
              leading: const Icon(Icons.local_cafe_outlined),
              title: const Text('Menu Produk'),
              onTap: () => context.push(RouteNames.produk),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Pelanggan'),
              onTap: () => context.push(RouteNames.pelanggan),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Pengeluaran'),
              onTap: () => context.push(RouteNames.pengeluaran),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              onTap: () => context.push(RouteNames.pengaturan),
            ),
            const Spacer(),
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
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
