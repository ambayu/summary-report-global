import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryRed = Color(0xFFB3261E);
  static const Color primaryDark = Color(0xFF7F1D1D);
  static const String defaultThemeHex = '#B3261E';
  static const Color backgroundCream = Color(0xFFF7F1E8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color mutedGray = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);

  static const Color success = Color(0xFF15803D);
  static const Color danger = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFC2410C);

  static const List<String> themePaletteHex = [
    '#B3261E',
    '#0F766E',
    '#1D4ED8',
    '#7C3AED',
    '#EA580C',
    '#BE185D',
  ];

  static Color fromHex(String? hex) {
    final fallback = primaryRed;
    if (hex == null || hex.trim().isEmpty) return fallback;
    final value = hex.trim().replaceAll('#', '');
    final normalized = value.length == 6 ? 'FF$value' : value;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }
}
