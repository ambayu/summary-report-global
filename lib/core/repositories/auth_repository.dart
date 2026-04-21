import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
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

  AppSettings get _settings {
    final raw = LocalStorage.settingsBox.get('default');
    if (raw == null) {
      return const AppSettings(
        cafeName: 'Summary Cafe',
        logoBase64: null,
        taxPercent: 10,
        activePayments: [],
        roles: [],
        themeColorHex: '#B3261E',
      );
    }
    return AppSettings.fromMap(raw);
  }

  UserSession? get currentSession {
    final data = LocalStorage.sessionBox.get('current');
    if (data == null) return null;
    return UserSession.fromMap(data);
  }

  List<AppUser> getAllUsers() {
    final settings = _settings;
    final list = LocalStorage.usersBox.values.map(AppUser.fromMap).toList()
      ..sort((a, b) {
        final compareRole = settings
            .roleSortIndex(a.roleKey)
            .compareTo(settings.roleSortIndex(b.roleKey));
        if (compareRole != 0) return compareRole;
        return a.username.compareTo(b.username);
      });
    return list;
  }

  Future<UserSession> login({
    required String name,
    required String password,
    required String roleKey,
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
    if (user.roleKey != roleKey) {
      throw Exception('Role tidak sesuai dengan akun yang dipilih');
    }

    final session = UserSession(
      id: _uuid.v4(),
      name: user.username,
      roleKey: user.roleKey,
      roleLabel: user.roleLabel,
      loggedInAt: DateTime.now(),
    );

    await LocalStorage.sessionBox.put('current', session.toMap());
    return session;
  }

  Future<void> createUser({
    required String username,
    required String password,
    required RoleDefinition role,
  }) async {
    final current = currentSession;
    if (current == null || !AppRole.isOwner(current.roleKey)) {
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

    final roleDefinition = _settings.assignableRoles.firstWhere(
      (item) => item.key == role.key,
      orElse: () => throw Exception('Role tidak ditemukan'),
    );

    final now = DateTime.now();
    final user = AppUser(
      id: _uuid.v4(),
      username: normalizedUsername,
      password: normalizedPassword,
      roleKey: roleDefinition.key,
      roleLabel: roleDefinition.label,
      createdAt: now,
      updatedAt: now,
    );

    await LocalStorage.usersBox.put(user.username, user.toMap());
  }

  Future<void> updateUser({
    required String currentUsername,
    required String newUsername,
    String? newPassword,
    RoleDefinition? role,
  }) async {
    final current = currentSession;
    if (current == null || !AppRole.isOwner(current.roleKey)) {
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
    final nextRole = role == null
        ? null
        : _settings.roles.firstWhere(
            (item) => item.key == role.key,
            orElse: () => throw Exception('Role tidak ditemukan'),
          );
    if (AppRole.isOwner(existing.roleKey) &&
        nextRole != null &&
        !AppRole.isOwner(nextRole.key)) {
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
      roleKey: nextRole?.key ?? existing.roleKey,
      roleLabel: nextRole?.label ?? existing.roleLabel,
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
        roleKey: updated.roleKey,
        roleLabel: updated.roleLabel,
        loggedInAt: current.loggedInAt,
      );
      await LocalStorage.sessionBox.put('current', nextSession.toMap());
    }
  }

  Future<void> deleteUser(String username) async {
    final current = currentSession;
    if (current == null || !AppRole.isOwner(current.roleKey)) {
      throw Exception('Hanya owner yang dapat menghapus user');
    }

    final normalizedUsername = _normalizeUsername(username);
    final data = LocalStorage.usersBox.get(normalizedUsername);
    if (data == null) {
      throw Exception('User tidak ditemukan');
    }

    final user = AppUser.fromMap(data);
    if (AppRole.isOwner(user.roleKey)) {
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
