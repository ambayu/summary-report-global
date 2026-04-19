enum UserRole { owner, admin, kasir }

enum AppPermission {
  dashboard,
  transaksi,
  riwayat,
  laporan,
  produk,
  pelanggan,
  pengeluaran,
  pengaturan,
  manageUsers,
}

enum PaymentMethod { cash, qris, debitKredit, ewallet, transfer }

enum TransactionStatus { lunas, pending, splitBill, refund, batal }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.kasir:
        return 'Kasir';
    }
  }

  List<AppPermission> get permissions {
    switch (this) {
      case UserRole.owner:
        return AppPermission.values;
      case UserRole.admin:
        return const [
          AppPermission.dashboard,
          AppPermission.transaksi,
          AppPermission.riwayat,
          AppPermission.laporan,
          AppPermission.produk,
          AppPermission.pelanggan,
          AppPermission.pengeluaran,
        ];
      case UserRole.kasir:
        return const [
          AppPermission.dashboard,
          AppPermission.transaksi,
          AppPermission.riwayat,
        ];
    }
  }

  bool hasPermission(AppPermission permission) {
    return permissions.contains(permission);
  }
}

extension AppPermissionX on AppPermission {
  String get label {
    switch (this) {
      case AppPermission.dashboard:
        return 'Dashboard';
      case AppPermission.transaksi:
        return 'Transaksi';
      case AppPermission.riwayat:
        return 'Riwayat';
      case AppPermission.laporan:
        return 'Laporan';
      case AppPermission.produk:
        return 'Menu Produk';
      case AppPermission.pelanggan:
        return 'Pelanggan';
      case AppPermission.pengeluaran:
        return 'Pengeluaran';
      case AppPermission.pengaturan:
        return 'Pengaturan';
      case AppPermission.manageUsers:
        return 'Manajemen User';
    }
  }
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.debitKredit:
        return 'Debit/Kredit';
      case PaymentMethod.ewallet:
        return 'E-Wallet';
      case PaymentMethod.transfer:
        return 'Transfer';
    }
  }
}

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.lunas:
        return 'Lunas';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.splitBill:
        return 'Split Bill';
      case TransactionStatus.refund:
        return 'Refund';
      case TransactionStatus.batal:
        return 'Batal';
    }
  }
}
