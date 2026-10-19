// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  language: json['language'] as String? ?? 'es',
  themeMode:
      $enumDecodeNullable(
        _$AppThemeModeEnumMap,
        json['theme'],
        unknownValue: AppThemeMode.dark,
      ) ??
      AppThemeMode.dark,
  notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
  cyberUsername: json['cyber_username'] as String? ?? 'OPERADOR_NEON',
  timeFormat:
      $enumDecodeNullable(
        _$TimeFormatPrefEnumMap,
        json['time_format'],
        unknownValue: TimeFormatPref.h24,
      ) ??
      TimeFormatPref.h24,
  dateFormat: json['date_format'] as String? ?? 'YYYY-MM-DD',
  persistentNotification: json['persistent_notification'] as bool? ?? false,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'language': instance.language,
      'theme': _$AppThemeModeEnumMap[instance.themeMode]!,
      'notifications_enabled': instance.notificationsEnabled,
      'cyber_username': instance.cyberUsername,
      'time_format': _$TimeFormatPrefEnumMap[instance.timeFormat]!,
      'date_format': instance.dateFormat,
      'persistent_notification': instance.persistentNotification,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
  AppThemeMode.system: 'system',
};

const _$TimeFormatPrefEnumMap = {
  TimeFormatPref.h24: '24h',
  TimeFormatPref.h12: '12h',
};
