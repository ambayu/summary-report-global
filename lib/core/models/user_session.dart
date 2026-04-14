import 'enums.dart';

class UserSession {
  const UserSession({
    required this.id,
    required this.name,
    required this.role,
    required this.loggedInAt,
  });

  final String id;
  final String name;
  final UserRole role;
  final DateTime loggedInAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'loggedInAt': loggedInAt.toIso8601String(),
    };
  }

  factory UserSession.fromMap(Map<dynamic, dynamic> map) {
    return UserSession(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => UserRole.kasir,
      ),
      loggedInAt:
          DateTime.tryParse(map['loggedInAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
