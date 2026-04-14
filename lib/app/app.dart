import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SummaryApp extends StatelessWidget {
  const SummaryApp({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(initialLocation: initialLocation).router;
    return MaterialApp.router(
      title: 'Summary Report Cafe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
