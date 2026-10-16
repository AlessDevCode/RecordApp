// lib/features/settings/domain/models/time_format_pref.dart
import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum TimeFormatPref {
  h24('24h'),
  h12('12h');

  const TimeFormatPref(this.value);

  final String value;
}
