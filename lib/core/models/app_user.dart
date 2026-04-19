import 'enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String password;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser copyWith({
    String? username,
    String? password,
    UserRole? role,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (item) => item.name == map['role'],
        orElse: () => UserRole.kasir,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
