import 'enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.roleKey,
    required this.roleLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String password;
  final String roleKey;
  final String roleLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser copyWith({
    String? username,
    String? password,
    String? roleKey,
    String? roleLabel,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      password: password ?? this.password,
      roleKey: roleKey ?? this.roleKey,
      roleLabel: roleLabel ?? this.roleLabel,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': roleKey,
      'roleKey': roleKey,
      'roleLabel': roleLabel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    final roleKey =
        map['roleKey']?.toString() ??
        map['role']?.toString() ??
        AppRole.pegawai;
    return AppUser(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      roleKey: roleKey,
      roleLabel:
          map['roleLabel']?.toString() ?? AppRole.labelForKey(roleKey),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
