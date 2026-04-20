import 'enums.dart';

class AppSettings {
  const AppSettings({
    required this.cafeName,
    required this.logoBase64,
    required this.taxPercent,
    required this.activePayments,
    required this.roles,
  });

  final String cafeName;
  final String? logoBase64;
  final double taxPercent;
  final List<PaymentMethod> activePayments;
  final List<RoleDefinition> roles;

  AppSettings copyWith({
    String? cafeName,
    String? logoBase64,
    double? taxPercent,
    List<PaymentMethod>? activePayments,
    List<RoleDefinition>? roles,
  }) {
    return AppSettings(
      cafeName: cafeName ?? this.cafeName,
      logoBase64: logoBase64 ?? this.logoBase64,
      taxPercent: taxPercent ?? this.taxPercent,
      activePayments: activePayments ?? this.activePayments,
      roles: roles ?? this.roles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cafeName': cafeName,
      'logoBase64': logoBase64,
      'taxPercent': taxPercent,
      'activePayments': activePayments.map((payment) => payment.name).toList(),
      'roles': roles.map((role) => role.toMap()).toList(),
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    final paymentList = (map['activePayments'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();
    final rawLegacyPermissions =
        (map['rolePermissions'] as Map?)?.cast<dynamic, dynamic>() ?? {};

    final roles = _parseRoles(
      rawRoles: map['roles'],
      legacyPermissions: rawLegacyPermissions,
    );

    return AppSettings(
      cafeName: map['cafeName']?.toString() ?? 'Cafe Kamu',
      logoBase64: map['logoBase64']?.toString(),
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 10,
      activePayments: paymentList
          .map(
            (name) => PaymentMethod.values.firstWhere(
              (method) => method.name == name,
              orElse: () => PaymentMethod.cash,
            ),
          )
          .toList(),
      roles: roles,
    );
  }

  RoleDefinition? roleByKey(String? roleKey) {
    if (roleKey == null || roleKey.trim().isEmpty) return null;
    for (final role in roles) {
      if (role.key == roleKey) return role;
    }
    return null;
  }

  String roleLabel(String? roleKey) {
    final role = roleByKey(roleKey);
    if (role != null) return role.label;
    if (roleKey == null || roleKey.trim().isEmpty) return '-';
    return AppRole.labelForKey(roleKey);
  }

  List<RoleDefinition> get assignableRoles {
    return roles.where((role) => !AppRole.isOwner(role.key)).toList();
  }

  int roleSortIndex(String? roleKey) {
    final index = roles.indexWhere((role) => role.key == roleKey);
    return index >= 0 ? index : 999;
  }

  List<AppPermission> permissionsForRoleKey(String? roleKey) {
    if (AppRole.isOwner(roleKey)) return AppPermission.values;

    final role = roleByKey(roleKey);
    if (role != null) return role.permissions;
    if (roleKey == null || roleKey.trim().isEmpty) return const [];
    return AppRole.defaultPermissionsFor(roleKey);
  }

  bool hasPermission(String? roleKey, AppPermission permission) {
    return permissionsForRoleKey(roleKey).contains(permission);
  }

  static List<RoleDefinition> defaultRoles() {
    return AppRole.sortDefinitions([
      RoleDefinition(
        key: AppRole.owner,
        label: AppRole.labelForKey(AppRole.owner),
        permissions: AppPermission.values,
        isSystem: true,
      ),
      RoleDefinition(
        key: AppRole.admin,
        label: AppRole.labelForKey(AppRole.admin),
        permissions: AppRole.defaultPermissionsFor(AppRole.admin),
        isSystem: true,
      ),
      RoleDefinition(
        key: AppRole.kasir,
        label: AppRole.labelForKey(AppRole.kasir),
        permissions: AppRole.defaultPermissionsFor(AppRole.kasir),
        isSystem: true,
      ),
      RoleDefinition(
        key: AppRole.pegawai,
        label: AppRole.labelForKey(AppRole.pegawai),
        permissions: AppRole.defaultPermissionsFor(AppRole.pegawai),
        isSystem: true,
      ),
    ]);
  }

  static List<RoleDefinition> _parseRoles({
    required dynamic rawRoles,
    required Map<dynamic, dynamic> legacyPermissions,
  }) {
    final parsed = <RoleDefinition>[];

    if (rawRoles is List) {
      for (final raw in rawRoles) {
        if (raw is Map) {
          parsed.add(RoleDefinition.fromMap(raw.cast<dynamic, dynamic>()));
        }
      }
    }

    final byKey = <String, RoleDefinition>{};

    for (final role in parsed) {
      if (role.key.trim().isEmpty) continue;
      byKey[role.key] = role.copyWith(
        permissions: role.permissions.toSet().toList(),
        isSystem: role.isSystem || AppRole.isSystemRole(role.key),
      );
    }

    for (final roleKey in AppRole.systemOrder) {
      final legacyRaw = legacyPermissions[roleKey];
      final legacyParsed = legacyRaw is List
          ? legacyRaw
                .map((value) => value.toString())
                .map(
                  (name) => AppPermission.values.firstWhere(
                    (permission) => permission.name == name,
                    orElse: () => AppPermission.dashboard,
                  ),
                )
                .toSet()
                .toList()
          : null;
      final current = byKey[roleKey];
      byKey[roleKey] = RoleDefinition(
        key: roleKey,
        label: current?.label ?? AppRole.labelForKey(roleKey),
        permissions: roleKey == AppRole.owner
            ? AppPermission.values
            : (current?.permissions ??
                  legacyParsed ??
                  AppRole.defaultPermissionsFor(roleKey)),
        isSystem: true,
      );
    }

    return AppRole.sortDefinitions(byKey.values.toList());
  }
}
