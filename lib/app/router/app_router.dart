import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/laporan/laporan_detail_page.dart';
import '../../features/laporan/laporan_filter_page.dart';
import '../../features/laporan/laporan_page.dart';
import '../../features/pelanggan/pelanggan_page.dart';
import '../../features/pengaturan/pengaturan_page.dart';
import '../../features/pengeluaran/pengeluaran_page.dart';
import '../../features/profil/profil_page.dart';
import '../../features/produk/produk_page.dart';
import '../../features/riwayat/pembayaran_detail_page.dart';
import '../../features/riwayat/riwayat_detail_page.dart';
import '../../features/riwayat/riwayat_page.dart';
import '../../features/shell/main_shell.dart';
import '../../features/transaksi/new_transaction_page.dart';
import '../../features/transaksi/transaction_detail_page.dart';
import '../../features/transaksi/transaksi_page.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter({required this.initialLocation});

  final String initialLocation;

  GoRouter get router => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.transaksi,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TransaksiPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.riwayat,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RiwayatPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.laporan,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: LaporanPage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.transaksiBaru,
        builder: (context, state) => const NewTransactionPage(),
      ),
      GoRoute(
        path: RouteNames.transaksiDetail,
        builder: (context, state) => TransactionDetailPage(
          transactionId: state.pathParameters['transactionId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.riwayatDetail,
        builder: (context, state) => RiwayatDetailPage(
          transactionId: state.pathParameters['transactionId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.pembayaranDetail,
        builder: (context, state) => PembayaranDetailPage(
          paymentId: state.pathParameters['paymentId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.laporanFilter,
        builder: (context, state) => const LaporanFilterPage(),
      ),
      GoRoute(
        path: RouteNames.laporanDetail,
        builder: (context, state) => LaporanDetailPage(
          reportType: state.pathParameters['reportType'] ?? 'harian',
        ),
      ),
      GoRoute(
        path: RouteNames.produk,
        builder: (context, state) => const ProdukPage(),
      ),
      GoRoute(
        path: RouteNames.pelanggan,
        builder: (context, state) => const PelangganPage(),
      ),
      GoRoute(
        path: RouteNames.pengeluaran,
        builder: (context, state) => const PengeluaranPage(),
      ),
      GoRoute(
        path: RouteNames.pengaturan,
        builder: (context, state) => const PengaturanPage(),
      ),
      GoRoute(
        path: RouteNames.profil,
        builder: (context, state) => const ProfilPage(),
      ),
    ],
  );
}
