// lib/features/tasks/domain/models/completed_entry.dart
import 'package:recordapp/features/tasks/domain/models/task.dart';

/// Una fila de la pestaña COMPLETADAS: o bien una misión normal finalizada, o
/// bien una ejecución concreta de una rutina (una fecha del historial).
class CompletedEntry {
  const CompletedEntry({required this.tarea, this.fecha});

  final Task tarea;

  /// Fecha (`YYYY-MM-DD`) de la ejecución marcada en una rutina. Null cuando
  /// es una misión normal completada.
  final String? fecha;

  bool get esEjecucion => fecha != null;

  /// Clave para ordenar de más reciente a más antigua (`YYYY-MM-DD`).
  String get claveOrden {
    final String? f = fecha;
    if (f != null) return f;
    if (tarea.fechaLimite.isNotEmpty) return tarea.fechaLimite;
    return tarea.fechaCreacion.length >= 10
        ? tarea.fechaCreacion.substring(0, 10)
        : '';
  }
}