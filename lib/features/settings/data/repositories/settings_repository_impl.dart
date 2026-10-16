// lib/features/settings/data/repositories/settings_repository_impl.dart
import 'package:flutter/foundation.dart';
import 'package:recordapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._datasource);

  final SettingsLocalDatasource _datasource;

  @override
  Future<AppSettings> loadSettings() async {
    try {
      final Map<String, Object?> stored = await _datasource.readAll();
      if (stored.isEmpty) {
        const AppSettings defaults = AppSettings();
        await _datasource.writeAll(
          Map<String, Object?>.from(defaults.toJson()),
        );
        return defaults;
      }
      return AppSettings.fromJson(stored);
    } catch (e, stackTrace) {
      debugPrint('❌ [SETTINGS_REPOSITORY] // Fallo al cargar configuración: $e');
      debugPrintStack(stackTrace: stackTrace);
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _datasource.writeAll(Map<String, Object?>.from(settings.toJson()));
  }
}
