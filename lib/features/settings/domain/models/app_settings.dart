// lib/features/settings/domain/models/app_settings.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:recordapp/features/settings/domain/models/app_theme_mode.dart';
import 'package:recordapp/features/settings/domain/models/time_format_pref.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('es') String language,
    @JsonKey(name: 'theme', unknownEnumValue: AppThemeMode.dark)
    @Default(AppThemeMode.dark)
    AppThemeMode themeMode,
    @JsonKey(name: 'notifications_enabled')
    @Default(true)
    bool notificationsEnabled,
    @JsonKey(name: 'cyber_username')
    @Default('ALESSANDRO')
    String cyberUsername,
    @JsonKey(name: 'time_format', unknownEnumValue: TimeFormatPref.h24)
    @Default(TimeFormatPref.h24)
    TimeFormatPref timeFormat,
    @JsonKey(name: 'date_format') @Default('YYYY-MM-DD') String dateFormat,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, Object?> json) =>
      _$AppSettingsFromJson(json);
}
