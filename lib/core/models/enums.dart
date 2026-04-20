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

const transactionVariants = <String>['Normal', 'Hot', 'Cold'];
const transactionOrderTypes = <String>['Dine In', 'Take Away'];

const roleConfigurablePermissions = <AppPermission>[
  AppPermission.dashboard,
  AppPermission.transaksi,
  AppPermission.riwayat,
  AppPermission.laporan,
  AppPermission.produk,
  AppPermission.pelanggan,
  AppPermission.pengeluaran,
  AppPermission.pengaturan,
];

class AppRole {
  static const owner = 'owner';
  static const admin = 'admin';
  static const kasir = 'kasir';
  static const pegawai = 'pegawai';

  static const systemOrder = <String>[owner, admin, kasir, pegawai];

  static const systemLabels = <String, String>{
    owner: 'Owner',
    admin: 'Admin',
    kasir: 'Kasir',
    pegawai: 'Pegawai',
  };

  static bool isOwner(String? roleKey) => roleKey == owner;

  static bool isSystemRole(String roleKey) => systemOrder.contains(roleKey);

  static String labelForKey(String roleKey) {
    if (systemLabels.containsKey(roleKey)) {
      return systemLabels[roleKey]!;
    }

    return roleKey
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String normalizeKey(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (normalized.isEmpty) return '';
    if (RegExp(r'^[0-9]').hasMatch(normalized)) {
      return 'role_$normalized';
    }
    return normalized;
  }

  static List<AppPermission> defaultPermissionsFor(String roleKey) {
    switch (roleKey) {
      case owner:
        return AppPermission.values;
      case admin:
        return const [
          AppPermission.dashboard,
          AppPermission.transaksi,
          AppPermission.riwayat,
          AppPermission.laporan,
          AppPermission.produk,
          AppPermission.pelanggan,
          AppPermission.pengeluaran,
          AppPermission.pengaturan,
        ];
      case kasir:
        return const [
          AppPermission.dashboard,
          AppPermission.transaksi,
          AppPermission.riwayat,
        ];
      case pegawai:
        return const [AppPermission.dashboard, AppPermission.transaksi];
      default:
        return const [AppPermission.dashboard];
    }
  }

  static List<RoleDefinition> sortDefinitions(List<RoleDefinition> roles) {
    final next = [...roles];
    next.sort((a, b) {
      final aSystemIndex = systemOrder.indexOf(a.key);
      final bSystemIndex = systemOrder.indexOf(b.key);

      if (aSystemIndex >= 0 || bSystemIndex >= 0) {
        if (aSystemIndex < 0) return 1;
        if (bSystemIndex < 0) return -1;
        return aSystemIndex.compareTo(bSystemIndex);
      }

      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return next;
  }
}

class RoleDefinition {
  const RoleDefinition({
    required this.key,
    required this.label,
    required this.permissions,
    this.isSystem = false,
  });

  final String key;
  final String label;
  final List<AppPermission> permissions;
  final bool isSystem;

  RoleDefinition copyWith({
    String? key,
    String? label,
    List<AppPermission>? permissions,
    bool? isSystem,
  }) {
    return RoleDefinition(
      key: key ?? this.key,
      label: label ?? this.label,
      permissions: permissions ?? this.permissions,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'permissions': permissions.map((permission) => permission.name).toList(),
      'isSystem': isSystem,
    };
  }

  factory RoleDefinition.fromMap(Map<dynamic, dynamic> map) {
    final rawPermissions = (map['permissions'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();
    final permissions = rawPermissions
        .map(
          (name) => AppPermission.values.firstWhere(
            (permission) => permission.name == name,
            orElse: () => AppPermission.dashboard,
          ),
        )
        .toSet()
        .toList();

    final key = map['key']?.toString() ?? '';
    final rawLabel = map['label']?.toString().trim() ?? '';
    return RoleDefinition(
      key: key,
      label: rawLabel.isEmpty ? AppRole.labelForKey(key) : rawLabel,
      permissions: permissions.isEmpty
          ? AppRole.defaultPermissionsFor(key)
          : permissions,
      isSystem: map['isSystem'] == true || AppRole.isSystemRole(key),
    );
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
