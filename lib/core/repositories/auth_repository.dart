import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

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
    if (name.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Nama user dan password wajib diisi');
    }

    final session = UserSession(
      id: _uuid.v4(),
      name: name.trim(),
      role: role,
      loggedInAt: DateTime.now(),
    );

    await LocalStorage.sessionBox.put('current', session.toMap());
    return session;
  }

  Future<void> logout() async {
    await LocalStorage.sessionBox.delete('current');
  }
}
