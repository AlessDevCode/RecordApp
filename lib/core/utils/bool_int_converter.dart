// lib/core/utils/bool_int_converter.dart
import 'package:json_annotation/json_annotation.dart';

/// Convierte el entero 0/1 de SQLite en bool y viceversa.
class BoolIntConverter implements JsonConverter<bool, int?> {
  const BoolIntConverter();

  @override
  bool fromJson(int? json) => json == 1;

  @override
  int toJson(bool object) => object ? 1 : 0;
}
