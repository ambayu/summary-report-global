import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/user_session.dart';
import '../storage/local_storage.dart';

class AuthRepository {
  static const _uuid = Uuid();

  ValueListenable<Box<Map>> get listenable {
    return LocalStorage.sessionBox.listenable(keys: const ['current']);
  }

  ValueListenable<Box<Map>> get usersListenable {
    return LocalStorage.usersBox.listenable();
  }

  UserSession? get currentSession {
    final data = LocalStorage.sessionBox.get('current');
    if (data == null) return null;
    return UserSession.fromMap(data);
  }

  List<AppUser> getAllUsers() {
    final roleOrder = {
      UserRole.owner: 0,
      UserRole.admin: 1,
      UserRole.kasir: 2,
    };

    final list = LocalStorage.usersBox.values.map(AppUser.fromMap).toList()
      ..sort((a, b) {
        final compareRole =
            (roleOrder[a.role] ?? 99).compareTo(roleOrder[b.role] ?? 99);
        if (compareRole != 0) return compareRole;
        return a.username.compareTo(b.username);
      });
    return list;
  }

  Future<UserSession> login({
    required String name,
    required String password,
    required UserRole role,
  }) async {
    final username = _normalizeUsername(name);
    final rawPassword = password.trim();
    if (username.isEmpty || rawPassword.isEmpty) {
      throw Exception('Nama user dan password wajib diisi');
    }

    final data = LocalStorage.usersBox.get(username);
    if (data == null) {
      throw Exception('User tidak ditemukan');
    }

    final user = AppUser.fromMap(data);
    if (user.password != rawPassword) {
      throw Exception('Password salah');
    }
    if (user.role != role) {
      throw Exception('Role tidak sesuai dengan akun yang dipilih');
    }

    final session = UserSession(
      id: _uuid.v4(),
      name: user.username,
      role: user.role,
      loggedInAt: DateTime.now(),
    );

    await LocalStorage.sessionBox.put('current', session.toMap());
    return session;
  }

  Future<void> createUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final current = currentSession;
    if (current == null || current.role != UserRole.owner) {
      throw Exception('Hanya owner yang dapat menambah user');
    }

    final normalizedUsername = _normalizeUsername(username);
    final normalizedPassword = password.trim();

    if (normalizedUsername.isEmpty) {
      throw Exception('Username wajib diisi');
    }
    if (normalizedPassword.length < 4) {
      throw Exception('Password minimal 4 karakter');
    }
    if (LocalStorage.usersBox.containsKey(normalizedUsername)) {
      throw Exception('Username sudah digunakan');
    }

    final now = DateTime.now();
    final user = AppUser(
      id: _uuid.v4(),
      username: normalizedUsername,
      password: normalizedPassword,
      role: role,
      createdAt: now,
      updatedAt: now,
    );

    await LocalStorage.usersBox.put(user.username, user.toMap());
  }

  Future<void> updateUser({
    required String currentUsername,
    required String newUsername,
    String? newPassword,
    UserRole? role,
  }) async {
    final current = currentSession;
    if (current == null || current.role != UserRole.owner) {
      throw Exception('Hanya owner yang dapat mengubah user');
    }

    final normalizedCurrentUsername = _normalizeUsername(currentUsername);
    final normalizedNewUsername = _normalizeUsername(newUsername);
    final data = LocalStorage.usersBox.get(normalizedCurrentUsername);
    if (data == null) {
      throw Exception('User tidak ditemukan');
    }
    if (normalizedNewUsername.isEmpty) {
      throw Exception('Username wajib diisi');
    }

    final existing = AppUser.fromMap(data);
    final nextRole = role ?? existing.role;
    if (existing.role == UserRole.owner && nextRole != UserRole.owner) {
      throw Exception('Role owner tidak dapat diubah');
    }

    if (normalizedNewUsername != normalizedCurrentUsername &&
        LocalStorage.usersBox.containsKey(normalizedNewUsername)) {
      throw Exception('Username sudah digunakan');
    }

    final trimmedPassword = newPassword?.trim();
    if (trimmedPassword != null &&
        trimmedPassword.isNotEmpty &&
        trimmedPassword.length < 4) {
      throw Exception('Password minimal 4 karakter');
    }

    final updated = existing.copyWith(
      username: normalizedNewUsername,
      password: trimmedPassword != null && trimmedPassword.isNotEmpty
          ? trimmedPassword
          : existing.password,
      role: nextRole,
      updatedAt: DateTime.now(),
    );

    if (normalizedNewUsername != normalizedCurrentUsername) {
      await LocalStorage.usersBox.delete(normalizedCurrentUsername);
    }
    await LocalStorage.usersBox.put(updated.username, updated.toMap());

    if (current.name == normalizedCurrentUsername) {
      final nextSession = UserSession(
        id: current.id,
        name: updated.username,
        role: updated.role,
        loggedInAt: current.loggedInAt,
      );
      await LocalStorage.sessionBox.put('current', nextSession.toMap());
    }
  }

  Future<void> deleteUser(String username) async {
    final current = currentSession;
    if (current == null || current.role != UserRole.owner) {
      throw Exception('Hanya owner yang dapat menghapus user');
    }

    final normalizedUsername = _normalizeUsername(username);
    final data = LocalStorage.usersBox.get(normalizedUsername);
    if (data == null) {
      throw Exception('User tidak ditemukan');
    }

    final user = AppUser.fromMap(data);
    if (user.role == UserRole.owner) {
      throw Exception('Akun owner tidak dapat dihapus');
    }
    if (current.name == normalizedUsername) {
      throw Exception('Tidak bisa menghapus akun yang sedang dipakai');
    }

    await LocalStorage.usersBox.delete(normalizedUsername);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = currentSession;
    if (session == null) {
      throw Exception('Sesi login tidak ditemukan');
    }

    final data = LocalStorage.usersBox.get(_normalizeUsername(session.name));
    if (data == null) {
      throw Exception('User tidak ditemukan');
    }

    final user = AppUser.fromMap(data);
    if (user.password != currentPassword.trim()) {
      throw Exception('Password saat ini tidak sesuai');
    }

    final nextPassword = newPassword.trim();
    if (nextPassword.length < 4) {
      throw Exception('Password baru minimal 4 karakter');
    }
    if (nextPassword == user.password) {
      throw Exception('Password baru harus berbeda dari password lama');
    }

    final updated = user.copyWith(
      password: nextPassword,
      updatedAt: DateTime.now(),
    );
    await LocalStorage.usersBox.put(updated.username, updated.toMap());
  }

  Future<void> logout() async {
    await LocalStorage.sessionBox.delete('current');
  }

  String _normalizeUsername(String value) {
    return value.trim().toLowerCase();
  }
}
