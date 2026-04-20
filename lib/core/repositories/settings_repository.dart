import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../storage/local_storage.dart';

class SettingsRepository {
  ValueListenable<Box<Map>> get listenable =>
      LocalStorage.settingsBox.listenable();

  AppSettings get settings {
    final raw = LocalStorage.settingsBox.get('default');
    if (raw == null) {
      return const AppSettings(
        cafeName: 'Summary Cafe',
        logoBase64: null,
        taxPercent: 10,
        activePayments: [],
        roles: [],
      );
    }

    return AppSettings.fromMap(raw);
  }

  Future<void> save(AppSettings value) async {
    await LocalStorage.settingsBox.put('default', value.toMap());
  }
}
