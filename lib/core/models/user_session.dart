import 'enums.dart';

class UserSession {
  const UserSession({
    required this.id,
    required this.name,
    required this.roleKey,
    required this.roleLabel,
    required this.loggedInAt,
  });

  final String id;
  final String name;
  final String roleKey;
  final String roleLabel;
  final DateTime loggedInAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': roleKey,
      'roleKey': roleKey,
      'roleLabel': roleLabel,
      'loggedInAt': loggedInAt.toIso8601String(),
    };
  }

  factory UserSession.fromMap(Map<dynamic, dynamic> map) {
    final roleKey =
        map['roleKey']?.toString() ??
        map['role']?.toString() ??
        AppRole.pegawai;
    return UserSession(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      roleKey: roleKey,
      roleLabel:
          map['roleLabel']?.toString() ?? AppRole.labelForKey(roleKey),
      loggedInAt:
          DateTime.tryParse(map['loggedInAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
