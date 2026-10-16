// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF00B8D4);

  static ThemeData get light =>
      _construir(ThemeData.light(useMaterial3: true), Brightness.light);

  static ThemeData get dark =>
      _construir(ThemeData.dark(useMaterial3: true), Brightness.dark);

  static ThemeData _construir(ThemeData base, Brightness brillo) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brillo,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
    );
  }
}
