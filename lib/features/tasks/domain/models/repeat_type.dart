// lib/features/tasks/domain/models/repeat_type.dart

/// Cómo se repite una misión.
enum RepeatType {
  /// Una sola vez, en su fecha límite.
  none('none'),

  /// Todas las semanas, en los días marcados (`repeat_days`).
  weekly('weekly'),

  /// Solo en las fechas elegidas (`custom_dates`).
  customDates('custom_dates');

  const RepeatType(this.value);

  /// Valor guardado en la columna `repeat_type`.
  final String value;

  static RepeatType fromValue(String? value) {
    for (final RepeatType tipo in values) {
      if (tipo.value == value) return tipo;
    }
    return RepeatType.none;
  }
}