// lib/features/settings/domain/models/app_theme_mode.dart
import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum AppThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  const AppThemeMode(this.value);

  final String value;
}
