// lib/features/alarms/presentation/providers/persistent_status_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recordapp/features/alarms/data/services/notification_service.dart';
import 'package:recordapp/features/alarms/domain/services/reminder_planner.dart';
import 'package:recordapp/features/alarms/presentation/providers/notification_providers.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/models/time_format_pref.dart';
import 'package:recordapp/features/settings/domain/services/translator.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/services/status_summary.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';

/// Proveedor del actualizador de la notificación permanente de estado.
/// (Definido a mano: no requiere generación de código.)
final Provider<PersistentStatusUpdater> persistentStatusUpdaterProvider =
    Provider<PersistentStatusUpdater>(
  (Ref ref) => PersistentStatusUpdater(ref),
);

/// Mantiene al día la notificación fija de la barra de estado: la misión o
/// alarma que requiere atención ahora o, si no hay, la siguiente por venir.
///
/// Quien lo use (el `AlarmHost`) lo invoca cada minuto (`clockProvider`), al
/// cambiar las misiones, al cambiar los ajustes y al volver a la app. Si la
/// opción está desactivada en preferencias, quita la notificación.
class PersistentStatusUpdater {
  PersistentStatusUpdater(this._ref);

  final Ref _ref;
  bool _ocupado = false;
  bool _pendiente = false;
  bool? _ultimaActivada;

  /// Evita ejecuciones solapadas: si llega otra petición mientras se
  /// actualiza, se repite una vez al terminar.
  Future<void> actualizar() async {
    if (_ocupado) {
      _pendiente = true;
      return;
    }
    _ocupado = true;
    try {
      do {
        _pendiente = false;
        await _actualizarUnaVez();
      } while (_pendiente);
    } finally {
      _ocupado = false;
    }
  }

  Future<void> _actualizarUnaVez() async {
    try {
      final AppSettings ajustes = await _ref.read(appSettingsProvider.future);
      final NotificationService servicio =
          _ref.read(notificationServiceProvider);

      if (_ultimaActivada != ajustes.persistentNotification) {
        _ultimaActivada = ajustes.persistentNotification;
        debugPrint(
          '📌 [STATUS] // Notificación fija ${_ultimaActivada! ? 'ACTIVADA' : 'DESACTIVADA'} '
          'en Preferencias.',
        );
      }

      if (!ajustes.persistentNotification) {
        await servicio.ocultarEstadoPermanente();
        return;
      }

      final List<Task> tareas = await _ref.read(taskListProvider.future);
      final Translator t = await _ref.read(translatorProvider.future);
      final DateTime ahora = DateTime.now();

      final StatusSummary resumen =
          StatusSummaryService.calcular(tareas, ahora: ahora);
      final ({String titulo, String cuerpo}) texto =
          _redactar(resumen, ajustes, t, ahora);

      await servicio.mostrarEstadoPermanente(
        titulo: texto.titulo,
        cuerpo: texto.cuerpo,
      );
    } catch (e, s) {
      debugPrint('❌ [STATUS] // Fallo al actualizar la notificación fija: $e');
      debugPrintStack(stackTrace: s, maxFrames: 6);
    }
  }

  ({String titulo, String cuerpo}) _redactar(
    StatusSummary r,
    AppSettings ajustes,
    Translator t,
    DateTime ahora,
  ) {
    final Task? tarea = r.tarea;
    final DateTime? cuando = r.cuando;
    if (r.tipo == StatusKind.ninguna || tarea == null || cuando == null) {
      return (
        titulo: t.t('status.title_none', fallback: 'RecordApp'),
        cuerpo: t.t('status.none', fallback: 'Sin alarmas pendientes'),
      );
    }

    final bool formato24h = ajustes.timeFormat == TimeFormatPref.h24;
    final String hora = TimeFormatter.formatearHora(
      TimeFormatter.horaDb(cuando),
      formato24h: formato24h,
    );

    // Más misiones pendientes además de la mostrada.
    final int otras = r.tipo == StatusKind.proxima
        ? r.pendientes - 1
        : r.pendientes;
    final String masPendientes = otras > 0
        ? t
            .t('status.more', fallback: '+{n} pendientes')
            .replaceAll('{n}', '$otras')
        : '';

    if (r.tipo == StatusKind.ahora) {
      final String linea = t
          .t('status.now_body', fallback: 'Venció a las {time}')
          .replaceAll('{time}', hora);
      return (
        titulo: t
            .t('status.now_title', fallback: '⏰ Ahora: {title}')
            .replaceAll('{title}', tarea.titulo),
        cuerpo: <String>[linea, if (masPendientes.isNotEmpty) masPendientes]
            .join('\n'),
      );
    }

    final String fecha = TimeFormatter.fechaDb(cuando);
    final String hoy = TimeFormatter.fechaDb(ahora);
    final String manana = TimeFormatter.fechaDb(
      DateTime(ahora.year, ahora.month, ahora.day + 1),
    );
    final String dia = fecha == hoy
        ? t.t('status.today', fallback: 'Hoy')
        : fecha == manana
            ? t.t('status.tomorrow', fallback: 'Mañana')
            : TimeFormatter.formatearFecha(fecha, patron: ajustes.dateFormat);
    final String restante = ReminderPlanner.formatearRestante(
      cuando.difference(ahora),
      detallado: true,
    );
    final String linea = t
        .t('status.next_body', fallback: '{day} · {time} · en {left}')
        .replaceAll('{day}', dia)
        .replaceAll('{time}', hora)
        .replaceAll('{left}', restante);

    return (
      titulo: t
          .t('status.next_title', fallback: 'Próxima: {title}')
          .replaceAll('{title}', tarea.titulo),
      cuerpo: <String>[linea, if (masPendientes.isNotEmpty) masPendientes]
          .join('\n'),
    );
  }
}