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

  UserSession? get currentSession {
    final data = LocalStorage.sessionBox.get('current');
    if (data == null) return null;
    return UserSession.fromMap(data);
  }

  Future<UserSession> login({
    required String name,
    required String password,
    required UserRole role,
  }) async {
    final username = name.trim();
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = currentSession;
    if (session == null) {
      throw Exception('Sesi login tidak ditemukan');
    }

    final data = LocalStorage.usersBox.get(session.name);
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
}
