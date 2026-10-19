// lib/features/settings/presentation/providers/settings_providers.dart
import 'package:flutter/material.dart' show ThemeMode;
import 'package:recordapp/core/database/database_provider.dart';
import 'package:recordapp/features/settings/data/datasources/locale_asset_datasource.dart';
import 'package:recordapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:recordapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/models/app_theme_mode.dart';
import 'package:recordapp/features/settings/domain/models/time_format_pref.dart';
import 'package:recordapp/features/settings/domain/repositories/settings_repository.dart';
import 'package:recordapp/features/settings/domain/services/translator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
SettingsLocalDatasource settingsLocalDatasource(Ref ref) {
  return SettingsLocalDatasource(ref.watch(databaseHelperProvider));
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepositoryImpl(ref.watch(settingsLocalDatasourceProvider));
}

@Riverpod(keepAlive: true)
LocaleAssetDatasource localeAssetDatasource(Ref ref) {
  return const LocaleAssetDatasource();
}

/// Gestiona y persiste en SQLite toda la configuración, incluido el tema.
@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).loadSettings();
  }

  Future<void> _persistir(AppSettings Function(AppSettings) cambio) async {
    final AppSettings actual = state.value ?? await future;
    final AppSettings siguiente = cambio(actual);
    await ref.read(settingsRepositoryProvider).saveSettings(siguiente);
    state = AsyncData<AppSettings>(siguiente);
  }

  Future<void> setThemeMode(AppThemeMode modo) =>
      _persistir((AppSettings s) => s.copyWith(themeMode: modo));

  Future<void> setLanguage(String idioma) =>
      _persistir((AppSettings s) => s.copyWith(language: idioma));

  Future<void> setNotificationsEnabled({required bool habilitadas}) =>
      _persistir(
        (AppSettings s) => s.copyWith(notificationsEnabled: habilitadas),
      );

  Future<void> setPersistentNotification({required bool activada}) =>
      _persistir(
        (AppSettings s) => s.copyWith(persistentNotification: activada),
      );

  Future<void> setCyberUsername(String nombre) => _persistir(
        (AppSettings s) => s.copyWith(
          cyberUsername: nombre.trim().isEmpty ? s.cyberUsername : nombre.trim(),
        ),
      );

  Future<void> setTimeFormat(TimeFormatPref formato) =>
      _persistir((AppSettings s) => s.copyWith(timeFormat: formato));

  Future<void> setDateFormat(String formato) =>
      _persistir((AppSettings s) => s.copyWith(dateFormat: formato));
}

/// ThemeMode listo para `MaterialApp.themeMode`.
/// Solo notifica a sus dependientes cuando el modo cambia realmente.
@riverpod
ThemeMode appThemeMode(Ref ref) {
  final AppThemeMode modo =
      ref.watch(appSettingsProvider).value?.themeMode ?? AppThemeMode.dark;
  return switch (modo) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}

/// Idioma activo. Solo notifica cuando el código de idioma cambia.
@riverpod
String appLanguage(Ref ref) {
  return ref.watch(appSettingsProvider).value?.language ?? 'es';
}

/// Traductor reactivo: se reconstruye únicamente al cambiar el idioma.
@Riverpod(keepAlive: true)
Future<Translator> translator(Ref ref) async {
  final String idioma = ref.watch(appLanguageProvider);
  final Map<String, dynamic> diccionario =
      await ref.watch(localeAssetDatasourceProvider).load(idioma);
  return Translator(diccionario);
}