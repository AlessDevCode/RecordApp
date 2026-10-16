// lib/features/tasks/domain/services/routine_service.dart
import 'package:recordapp/features/tasks/domain/models/repeat_type.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';

/// Lógica de las misiones que se repiten (rutinas). Es lógica pura, sin
/// plugins ni estado, para poder probarla con tests unitarios.
abstract final class RoutineService {
  /// Etiquetas por defecto de los días, de lunes a domingo.
  static const String etiquetasDiasPorDefecto = 'L,M,M,J,V,S,D';

  /// Cuántas ocurrencias futuras se programan como máximo por rutina. Si la
  /// app no se abre en ese lapso, se retoman al abrirla.
  static const int maxEjecuciones = 14;

  /// Una rutina solo está en CRÍTICO durante esta ventana a partir de su hora
  /// programada de hoy. Pasada la ventana el estado desaparece solo.
  static const Duration ventanaCritica = Duration(minutes: 30);

  /// Cuántas ejecuciones se conservan en el historial de cada rutina.
  static const int maxHistorial = 120;

  static final RegExp _horaRegExp = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$');

  /// ¿Es una hora `HH:mm` válida?
  static bool horaValida(String hora) => _horaRegExp.hasMatch(hora.trim());

  /// Clave de [dia] en `repeatTimes`: el día de la semana (`"3"`) en rutinas
  /// semanales o la fecha (`2026-10-14`) en fechas especiales.
  static String claveDe(Task tarea, DateTime dia) =>
      tarea.repeatType == RepeatType.weekly
          ? '${dia.weekday}'
          : TimeFormatter.fechaDb(dia);

  /// Hora límite de la ocurrencia de [dia]: la de su bloque de horario si
  /// tiene uno, y si no la hora principal.
  static String horaDe(Task tarea, DateTime dia) {
    final String? propia = tarea.repeatTimes[claveDe(tarea, dia)];
    if (propia != null && horaValida(propia)) return propia.trim();
    return tarea.horaLimite;
  }

  /// ¿Esta rutina toca en [dia]? (según su día de la semana o sus fechas).
  static bool ocurreEn(Task tarea, DateTime dia) {
    switch (tarea.repeatType) {
      case RepeatType.weekly:
        return tarea.repeatDays.contains(dia.weekday);
      case RepeatType.customDates:
        return tarea.customDates.contains(TimeFormatter.fechaDb(dia));
      case RepeatType.none:
        return false;
    }
  }

  /// ¿Está marcada como hecha la ejecución de [dia]?
  static bool hechaEn(Task tarea, DateTime dia) =>
      tarea.doneDates.contains(TimeFormatter.fechaDb(dia));

  /// ¿Ya se marcó como hecha la ejecución de hoy?
  static bool hechaHoy(Task tarea, {DateTime? ahora}) =>
      hechaEn(tarea, ahora ?? DateTime.now());

  /// Ejecuciones marcadas, de la más reciente a la más antigua.
  static List<String> historial(Task tarea, {int max = maxHistorial}) {
    final List<String> fechas = tarea.doneDates.toList()
      ..sort((String a, String b) => b.compareTo(a));
    return fechas.length > max ? fechas.sublist(0, max) : fechas;
  }

  /// Próximas ocurrencias (instante exacto, con la hora que le corresponde a
  /// cada día), posteriores a [desde] y sin contar las ya cumplidas.
  static List<DateTime> proximasEjecuciones(
    Task tarea, {
    required DateTime desde,
    int max = maxEjecuciones,
  }) {
    if (!tarea.esRutina || max <= 0) return const <DateTime>[];

    final List<DateTime> resultado = <DateTime>[];
    final DateTime inicio = DateTime(desde.year, desde.month, desde.day);

    switch (tarea.repeatType) {
      case RepeatType.weekly:
        if (tarea.repeatDays.isEmpty) return const <DateTime>[];
        for (int i = 0; i < 400 && resultado.length < max; i++) {
          // DateTime normaliza los desbordes de día (p. ej. 32 de enero).
          final DateTime dia = DateTime(inicio.year, inicio.month, inicio.day + i);
          if (!tarea.repeatDays.contains(dia.weekday)) continue;
          _agregar(tarea, dia, desde, resultado);
        }
      case RepeatType.customDates:
        final List<String> fechas = tarea.customDates.toList()..sort();
        for (final String f in fechas) {
          if (resultado.length >= max) break;
          final DateTime? d = DateTime.tryParse(f);
          if (d == null) continue;
          _agregar(tarea, DateTime(d.year, d.month, d.day), desde, resultado);
        }
      case RepeatType.none:
        break;
    }
    return resultado;
  }

  static void _agregar(
    Task tarea,
    DateTime dia,
    DateTime desde,
    List<DateTime> salida,
  ) {
    final String fecha = TimeFormatter.fechaDb(dia);
    if (tarea.doneDates.contains(fecha)) return; // Ya cumplida.
    final DateTime? limite =
        TimeFormatter.parseLimite(fecha, horaDe(tarea, dia));
    if (limite == null || !limite.isAfter(desde)) return;
    salida.add(limite);
  }

  /// Próxima ocurrencia pendiente, o null si no queda ninguna.
  static DateTime? proximaEjecucion(Task tarea, {DateTime? ahora}) {
    final List<DateTime> lista = proximasEjecuciones(
      tarea,
      desde: ahora ?? DateTime.now(),
      max: 1,
    );
    return lista.isEmpty ? null : lista.first;
  }

  /// ¿Está vencida (estado CRÍTICO)?
  ///
  /// - Misión normal: su fecha límite pasó sin completarse.
  /// - Rutina: solo cuenta la ocurrencia de HOY y únicamente durante
  ///   [ventanaCritica] (30 min) desde su hora programada (la de su bloque, si
  ///   lo tiene), sin haberla marcado como hecha. Ejemplo: si era a las 11:30,
  ///   es crítica de 11:30 a 12:00. Pasada la ventana el estado desaparece y
  ///   la tarjeta muestra la siguiente ocurrencia futura; las ocurrencias
  ///   perdidas del pasado no dejan alertas acumuladas.
  static bool estaVencida(Task tarea, {DateTime? ahora}) {
    final DateTime ref = ahora ?? DateTime.now();

    if (!tarea.esRutina) {
      return !tarea.completada &&
          TimeFormatter.estaVencida(
            tarea.fechaLimite,
            tarea.horaLimite,
            ahora: ref,
          );
    }

    if (tarea.completada) return false;
    if (!ocurreEn(tarea, ref)) return false;
    if (hechaEn(tarea, ref)) return false;
    final DateTime? limite = TimeFormatter.parseLimite(
      TimeFormatter.fechaDb(ref),
      horaDe(tarea, ref),
    );
    if (limite == null) return false;
    return !ref.isBefore(limite) && !ref.isAfter(limite.add(ventanaCritica));
  }

  /// Resumen corto de la frecuencia para la tarjeta: `L M V` o `3 fechas`.
  /// [etiquetasDias] son 7 etiquetas de lunes a domingo.
  static String resumenFrecuencia(
    Task tarea, {
    required List<String> etiquetasDias,
    required String Function(int cantidad) textoFechas,
  }) {
    switch (tarea.repeatType) {
      case RepeatType.weekly:
        final List<int> dias = tarea.repeatDays.toList()..sort();
        return dias
            .where((int d) => d >= 1 && d <= etiquetasDias.length)
            .map((int d) => etiquetasDias[d - 1])
            .join(' ');
      case RepeatType.customDates:
        return textoFechas(tarea.customDates.length);
      case RepeatType.none:
        return '';
    }
  }
}