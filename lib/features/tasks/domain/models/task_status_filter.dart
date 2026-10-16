// lib/features/tasks/domain/models/task_status_filter.dart
enum TaskStatusFilter {
  enTiempo('EN TIEMPO'),
  critico('CRÍTICO'),

  /// Solo misiones que se repiten (rutinas). A diferencia de los otros dos,
  /// no es un estado: se combina con ellos (Y), no (O).
  rutinas('RUTINAS'),

  /// Historial: misiones normales finalizadas y ejecuciones marcadas de las
  /// rutinas. Excluye a EN TIEMPO y CRÍTICO; con RUTINAS muestra solo el
  /// historial de rutinas.
  completadas('COMPLETADAS');

  const TaskStatusFilter(this.value);

  final String value;
}