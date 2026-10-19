// lib/features/tasks/domain/services/status_summary.dart
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';

/// Qué debe mostrar la notificación permanente de estado.
enum StatusKind {
  /// Una misión o rutina cuya hora acaba de llegar (dentro de su ventana de
  /// 30 minutos) y sigue sin marcarse.
  ahora,

  /// La siguiente misión, alarma u ocurrencia de rutina por venir.
  proxima,

  /// No hay nada pendiente con fecha y hora.
  ninguna,
}

class StatusSummary {
  const StatusSummary({
    required this.tipo,
    this.tarea,
    this.cuando,
    this.pendientes = 0,
  });

  final StatusKind tipo;

  /// Misión protagonista (null si [tipo] es [StatusKind.ninguna]).
  final Task? tarea;

  /// Su hora límite exacta (la de hoy en [StatusKind.ahora]; la de la próxima
  /// ocurrencia en [StatusKind.proxima]).
  final DateTime? cuando;

  /// Cuántas misiones tienen una ocurrencia futura pendiente (cada misión
  /// cuenta una vez, también la protagonista de [StatusKind.proxima]).
  final int pendientes;
}

/// Calcula el resumen de estado a partir de las misiones. Es lógica pura, sin
/// plugins ni estado, para poder probarla con tests unitarios.
abstract final class StatusSummaryService {
  static StatusSummary calcular(
    List<Task> tareas, {
    required DateTime ahora,
  }) {
    Task? enCurso;
    DateTime? limiteEnCurso;

    Task? siguiente;
    DateTime? cuandoSiguiente;
    int pendientes = 0;

    for (final Task t in tareas) {
      if (t.completada) continue;

      // ¿Su hora de hoy acaba de pasar (ventana de 30 min) sin marcarse?
      final DateTime? limiteHoy = _limiteDeHoy(t, ahora);
      if (limiteHoy != null &&
          !limiteHoy.isAfter(ahora) &&
          ahora.difference(limiteHoy) <= RoutineService.ventanaCritica) {
        if (limiteEnCurso == null || limiteHoy.isBefore(limiteEnCurso)) {
          enCurso = t;
          limiteEnCurso = limiteHoy;
        }
      }

      // Próxima ocurrencia futura.
      final DateTime? proxima = t.esRutina
          ? RoutineService.proximaEjecucion(t, ahora: ahora)
          : (limiteHoy != null && limiteHoy.isAfter(ahora) ? limiteHoy : null);
      if (proxima == null) continue;
      pendientes++;
      if (cuandoSiguiente == null || proxima.isBefore(cuandoSiguiente)) {
        siguiente = t;
        cuandoSiguiente = proxima;
      }
    }

    if (enCurso != null) {
      return StatusSummary(
        tipo: StatusKind.ahora,
        tarea: enCurso,
        cuando: limiteEnCurso,
        pendientes: pendientes,
      );
    }
    if (siguiente != null) {
      return StatusSummary(
        tipo: StatusKind.proxima,
        tarea: siguiente,
        cuando: cuandoSiguiente,
        pendientes: pendientes,
      );
    }
    return const StatusSummary(tipo: StatusKind.ninguna);
  }

  /// Hora límite de la ocurrencia de HOY: la fecha límite de una misión normal
  /// o, en una rutina, la hora de hoy si le toca y no está marcada.
  static DateTime? _limiteDeHoy(Task t, DateTime ahora) {
    if (t.esRutina) {
      if (!RoutineService.ocurreEn(t, ahora)) return null;
      if (RoutineService.hechaEn(t, ahora)) return null;
      return TimeFormatter.parseLimite(
        TimeFormatter.fechaDb(ahora),
        RoutineService.horaDe(t, ahora),
      );
    }
    if (t.fechaLimite.trim().isEmpty) return null;
    return TimeFormatter.parseLimite(t.fechaLimite, t.horaLimite);
  }
}