class RouteNames {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';

  static const dashboard = '/dashboard';
  static const transaksi = '/transaksi';
  static const riwayat = '/riwayat';
  static const laporan = '/laporan';

  static const transaksiBaru = '/transaksi/new';
  static const transaksiDetail = '/transaksi/:transactionId';
  static const transaksiEdit = '/transaksi/:transactionId/edit';
  static const transaksiBayar = '/transaksi/:transactionId/payment';

  static const riwayatDetail = '/riwayat/:transactionId';
  static const pembayaranDetail = '/riwayat/payment/:paymentId';

  static const laporanFilter = '/laporan/filter';
  static const laporanDetail = '/laporan/detail/:reportType';

  static const produk = '/produk';
  static const produkTambah = '/produk/tambah';
  static const produkEdit = '/produk/:productId/edit';

  static const pelanggan = '/pelanggan';
  static const pelangganDetail = '/pelanggan/:customerId';

  static const pengeluaran = '/pengeluaran';
  static const pengeluaranEdit = '/pengeluaran/:expenseId/edit';

  static const pengaturan = '/pengaturan';
  static const manageRoles = '/manage-roles';
  static const manageUsers = '/manage-users';
  static const profil = '/profil';
}
