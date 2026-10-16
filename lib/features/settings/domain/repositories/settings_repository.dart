// lib/features/settings/domain/repositories/settings_repository.dart
import 'package:recordapp/features/settings/domain/models/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> loadSettings();

  Future<void> saveSettings(AppSettings settings);
}
