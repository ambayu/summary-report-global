import '../models/app_settings.dart';
import '../storage/local_storage.dart';

class SettingsRepository {
  AppSettings get settings {
    final raw = LocalStorage.settingsBox.get('default');
    if (raw == null) {
      return const AppSettings(
        cafeName: 'Summary Cafe',
        taxPercent: 10,
        servicePercent: 5,
        activePayments: [],
      );
    }

    return AppSettings.fromMap(raw);
  }

  Future<void> save(AppSettings value) async {
    await LocalStorage.settingsBox.put('default', value.toMap());
  }
}
