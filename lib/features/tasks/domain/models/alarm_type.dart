// lib/features/tasks/domain/models/alarm_type.dart
import 'package:json_annotation/json_annotation.dart';

/// Cómo se avisa al culminar el plazo de una misión.
@JsonEnum(valueField: 'value')
enum AlarmType {
  silencioso('SILENCIOSO'),
  sonido('SONIDO'),
  vibracion('VIBRACION');

  const AlarmType(this.value);

  final String value;
}
