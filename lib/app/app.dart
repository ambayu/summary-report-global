import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/models/app_settings.dart';
import '../core/storage/local_storage.dart';
import 'router/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class SummaryApp extends StatelessWidget {
  const SummaryApp({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: LocalStorage.settingsBox.listenable(),
      builder: (context, box, child) {
        final router = AppRouter(initialLocation: initialLocation).router;
        final raw = LocalStorage.settingsBox.get('default');
        final settings = raw == null
            ? const AppSettings(
                cafeName: 'Summary Cafe',
                logoBase64: null,
                taxPercent: 10,
                activePayments: [],
                roles: [],
                themeColorHex: '#B3261E',
              )
            : AppSettings.fromMap(raw);

        return MaterialApp.router(
          title: settings.cafeName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(
            primaryColor: AppColors.fromHex(settings.themeColorHex),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
