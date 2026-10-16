// lib/features/alarms/domain/services/reminder_planner.dart
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';

enum AlertKind {
  /// Aviso de estado cada 5 h desde la creación.
  recordatorio,

  /// Aviso de urgencia cada 90 min en las últimas 6 h.
  urgente,

  /// Aviso del instante límite (suena / vibra / silencioso según el modo).
  finalizacion,

  /// Repetición automática de la alerta final (mismo modo, sonido y
  /// duración), cada cierto número de minutos, hasta completar la misión.
  repeticion,
}

class PlannedAlert {
  const PlannedAlert({
    required this.id,
    required this.cuando,
    required this.tipo,
    required this.restante,
    this.numero = 0,
    this.total = 0,
  });

  final int id;
  final DateTime cuando;
  final AlertKind tipo;

  /// Tiempo que faltará para el límite en el momento de dispararse.
  final Duration restante;

  /// Solo en [AlertKind.repeticion]: qué repetición es (1…[total]).
  final int numero;
  final int total;
}

class MissionPlan {
  const MissionPlan({required this.tarea, required this.alertas});

  final Task tarea;
  final List<PlannedAlert> alertas;
}

/// Calcula qué notificaciones hay que programar. Es lógica pura (sin plugins)
/// para poder probarla con tests unitarios.
///
/// Reserva de IDs por misión (`idMision * 100 + índice`):
///   - 0       → finalización
///   - 1..9    → urgentes (90 min)
///   - 10..57  → recordatorios de 5 h
///   - 60..64  → repeticiones de la alerta final (hasta [maxRepeticiones])
///
/// Las rutinas no usan recordatorios: ocurrencia `i` → `i` (final) y
/// `14 + i*5 + (k-1)` (repetición `k`).
abstract final class ReminderPlanner {
  static const Duration intervaloNormal = Duration(hours: 5);
  static const Duration ventanaUrgente = Duration(hours: 6);
  static const Duration intervaloUrgente = Duration(minutes: 90);

  static const int idsPorMision = 100;
  static const int _indiceFinal = 0;
  static const int _primerIndiceUrgente = 1;
  static const int _primerIndiceNormal = 10;
  static const int _primerIndiceRepeticion = 60;
  static const int _primerIndiceRepeticionRutina = 14;

  /// Máximo de repeticiones automáticas de una alerta.
  static const int maxRepeticiones = 5;

  /// Máximo de recordatorios de 5 h por misión (≈ 10 días). Android limita
  /// las alarmas por app (≈ 500 en algunos Samsung), así que se programa una
  /// ventana deslizante que se renueva al abrir o reanudar la app.
  static const int maxNormalesPorMision = 48;

  /// Tope global de notificaciones pendientes entre todas las misiones.
  static const int presupuestoTotal = 400;

  static int idBase(int idMision) => idMision * idsPorMision;

  static int idMisionDe(int idNotificacion) => idNotificacion ~/ idsPorMision;

  /// Alertas futuras de una misión.
  static List<PlannedAlert> planificar({
    required int idMision,
    required DateTime creacion,
    required DateTime limite,
    required DateTime ahora,
    int maxNormales = maxNormalesPorMision,
    int repeticiones = 0,
    int intervaloMin = 0,
  }) {
    final int base = idBase(idMision);

    // Repeticiones de la alerta final que aún están por venir. Siguen
    // programadas aunque el límite ya haya pasado: así continúan sonando
    // hasta que la misión se complete, edite o elimine.
    final List<PlannedAlert> reintentos = _repeticionesDe(
      limite: limite,
      ahora: ahora,
      repeticiones: repeticiones,
      intervaloMin: intervaloMin,
      idDe: (int k) => base + _primerIndiceRepeticion + (k - 1),
    );
    if (!limite.isAfter(ahora)) return reintentos;

    final List<PlannedAlert> alertas = <PlannedAlert>[];
    final DateTime inicioUrgente = limite.subtract(ventanaUrgente);

    // Recordatorios normales: creación + 5h·k, mientras falten más de 6 h.
    final int pasoMin = intervaloNormal.inMinutes;
    final int transcurridoMin = ahora.difference(creacion).inMinutes;
    int k = transcurridoMin < 0 ? 1 : (transcurridoMin ~/ pasoMin) + 1;
    int indice = _primerIndiceNormal;
    int normales = 0;
    while (normales < maxNormales && indice < _primerIndiceRepeticion) {
      final DateTime t = creacion.add(intervaloNormal * k);
      k++;
      if (!t.isBefore(inicioUrgente)) break;
      if (!t.isAfter(ahora)) continue;
      alertas.add(
        PlannedAlert(
          id: base + indice,
          cuando: t,
          tipo: AlertKind.recordatorio,
          restante: limite.difference(t),
        ),
      );
      indice++;
      normales++;
    }

    // Urgentes: desde (límite - 6 h), cada 90 min, siempre antes del límite.
    for (int i = 0;; i++) {
      final DateTime t = inicioUrgente.add(intervaloUrgente * i);
      if (!t.isBefore(limite)) break;
      if (!t.isAfter(ahora)) continue;
      alertas.add(
        PlannedAlert(
          id: base + _primerIndiceUrgente + i,
          cuando: t,
          tipo: AlertKind.urgente,
          restante: limite.difference(t),
        ),
      );
    }

    alertas.add(
      PlannedAlert(
        id: base + _indiceFinal,
        cuando: limite,
        tipo: AlertKind.finalizacion,
        restante: Duration.zero,
      ),
    );
    alertas.addAll(reintentos);
    return alertas;
  }

  /// Repeticiones `k = 1..repeticiones` de una alerta que vence en [limite],
  /// una cada [intervaloMin] minutos, descartando las que ya pasaron.
  static List<PlannedAlert> _repeticionesDe({
    required DateTime limite,
    required DateTime ahora,
    required int repeticiones,
    required int intervaloMin,
    required int Function(int k) idDe,
  }) {
    final int n = repeticiones.clamp(0, maxRepeticiones).toInt();
    if (n == 0 || intervaloMin <= 0) return const <PlannedAlert>[];

    final List<PlannedAlert> resultado = <PlannedAlert>[];
    for (int k = 1; k <= n; k++) {
      final DateTime t = limite.add(Duration(minutes: intervaloMin * k));
      if (!t.isAfter(ahora)) continue;
      resultado.add(
        PlannedAlert(
          id: idDe(k),
          cuando: t,
          tipo: AlertKind.repeticion,
          restante: Duration.zero,
          numero: k,
          total: n,
        ),
      );
    }
    return resultado;
  }

  /// Duración total durante la cual una alerta aún tiene repeticiones
  /// pendientes después de su hora.
  static Duration ventanaDeRepeticion(Task t) {
    final int n = t.repeatCount.clamp(0, maxRepeticiones).toInt();
    if (n == 0 || t.intervalMinutes <= 0) return Duration.zero;
    return Duration(minutes: n * t.intervalMinutes);
  }

  /// Plan de varias misiones respetando [presupuestoTotal]: primero se
  /// reservan la finalización y las urgentes de todas (por orden de límite)
  /// y con lo que sobra se reparten los recordatorios de 5 h.
  static List<MissionPlan> planificarTareas(
    List<Task> tareas, {
    required DateTime ahora,
  }) {
    final List<MissionPlan> planes = <MissionPlan>[];
    int usados = 0;

    // Rutinas: solo la alerta de finalización de cada ocurrencia (sin
    // recordatorios de 5 h ni avisos urgentes, que serían ruido diario) y sus
    // repeticiones. Se incluye también la ocurrencia que ya sonó si todavía le
    // quedan repeticiones por venir.
    // Ids: ocurrencia i → idMision*100 + i; su repetición k →
    // idMision*100 + 14 + i*5 + (k-1).
    for (final Task t in tareas) {
      final int? id = t.id;
      if (id == null || t.completada || !t.esRutina) continue;
      final Duration ventana = ventanaDeRepeticion(t);
      final List<DateTime> ocurrencias = RoutineService.proximasEjecuciones(
        t,
        desde: ahora.subtract(ventana),
      );
      final int base = idBase(id);
      final List<PlannedAlert> alertas = <PlannedAlert>[];
      for (int i = 0; i < ocurrencias.length; i++) {
        if (ocurrencias[i].isAfter(ahora)) {
          alertas.add(
            PlannedAlert(
              id: base + i,
              cuando: ocurrencias[i],
              tipo: AlertKind.finalizacion,
              restante: Duration.zero,
            ),
          );
        }
        alertas.addAll(
          _repeticionesDe(
            limite: ocurrencias[i],
            ahora: ahora,
            repeticiones: t.repeatCount,
            intervaloMin: t.intervalMinutes,
            idDe: (int k) =>
                base +
                _primerIndiceRepeticionRutina +
                i * maxRepeticiones +
                (k - 1),
          ),
        );
      }
      if (alertas.isEmpty) continue;
      planes.add(MissionPlan(tarea: t, alertas: alertas));
      usados += alertas.length;
    }

    final List<_Candidata> candidatas = <_Candidata>[];
    for (final Task t in tareas) {
      final int? id = t.id;
      if (id == null || t.completada || t.esRutina) continue;
      final DateTime? limite = TimeFormatter.parseLimite(
        t.fechaLimite,
        t.horaLimite,
      );
      if (limite == null) continue;
      if (!limite.add(ventanaDeRepeticion(t)).isAfter(ahora)) continue;
      final DateTime creacion = DateTime.tryParse(t.fechaCreacion) ?? ahora;
      candidatas.add(_Candidata(t, id, creacion, limite));
    }
    candidatas.sort((_Candidata a, _Candidata b) => a.limite.compareTo(b.limite));

    for (final _Candidata c in candidatas) {
      usados += planificar(
        idMision: c.id,
        creacion: c.creacion,
        limite: c.limite,
        ahora: ahora,
        maxNormales: 0,
        repeticiones: c.tarea.repeatCount,
        intervaloMin: c.tarea.intervalMinutes,
      ).length;
    }
    int sobrante = presupuestoTotal - usados;
    if (sobrante < 0) sobrante = 0;

    for (final _Candidata c in candidatas) {
      final int permitidos =
          sobrante < maxNormalesPorMision ? sobrante : maxNormalesPorMision;
      final List<PlannedAlert> alertas = planificar(
        idMision: c.id,
        creacion: c.creacion,
        limite: c.limite,
        ahora: ahora,
        maxNormales: permitidos,
        repeticiones: c.tarea.repeatCount,
        intervaloMin: c.tarea.intervalMinutes,
      );
      sobrante -= alertas
          .where((PlannedAlert a) => a.tipo == AlertKind.recordatorio)
          .length;
      planes.add(MissionPlan(tarea: c.tarea, alertas: alertas));
    }
    return planes;
  }

  /// `1d 3h`, `22h`, y con [detallado] `1h 30m`.
  static String formatearRestante(Duration d, {bool detallado = false}) {
    final int total = d.inMinutes < 0 ? 0 : d.inMinutes;
    final int dias = total ~/ 1440;
    final int horas = (total % 1440) ~/ 60;
    final int minutos = total % 60;

    if (dias > 0) return horas > 0 ? '${dias}d ${horas}h' : '${dias}d';
    if (horas > 0) {
      return (detallado && minutos > 0) ? '${horas}h ${minutos}m' : '${horas}h';
    }
    return '${minutos}m';
  }
}

class _Candidata {
  const _Candidata(this.tarea, this.id, this.creacion, this.limite);

  final Task tarea;
  final int id;
  final DateTime creacion;
  final DateTime limite;
}