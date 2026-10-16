// lib/features/alarms/presentation/providers/notification_providers.dart
import 'package:flutter/foundation.dart';
import 'package:recordapp/features/alarms/data/services/alert_sound_catalog.dart';
import 'package:recordapp/features/alarms/data/services/notification_service.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';
import 'package:recordapp/features/alarms/domain/services/reminder_planner.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/services/translator.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService();

/// Audios detectados dinámicamente en `assets/audio/`.
@Riverpod(keepAlive: true)
Future<List<AlertSound>> alertSounds(Ref ref) {
  return const AlertSoundCatalog().cargar();
}

@Riverpod(keepAlive: true)
MissionNotificationScheduler missionNotificationScheduler(Ref ref) {
  return MissionNotificationScheduler(ref);
}

/// Traduce el plan de [ReminderPlanner] a notificaciones concretas (textos,
/// canal, sonido) y las programa en el sistema.
class MissionNotificationScheduler {
  MissionNotificationScheduler(this._ref);

  final Ref _ref;

  /// Programa (o reprograma) las alertas de una misión.
  Future<void> programarMision(Task tarea) {
    final int? id = tarea.id;
    if (id == null) return Future<void>.value();
    return _sincronizar(<Task>[tarea], soloMisiones: <int>{id});
  }

  /// Cancela todas las alertas de una misión (al completar o eliminar).
  Future<void> cancelarMision(int idMision) async {
    try {
      await _ref.read(notificationServiceProvider).cancelarMision(idMision);
    } catch (e) {
      debugPrint('❌ [NOTIFICATIONS] // Fallo al cancelar misión $idMision: $e');
    }
  }

  /// Recalcula todo el plan a partir de la lista completa de misiones.
  /// Se invoca al abrir la app, al reanudarla y al cambiar ajustes/idioma.
  Future<void> sincronizarTodas(List<Task> tareas) => _sincronizar(tareas);

  Future<void> _sincronizar(
    List<Task> tareas, {
    Set<int>? soloMisiones,
  }) async {
    try {
      final NotificationService servicio =
          _ref.read(notificationServiceProvider);
      final AppSettings ajustes = await _ref.read(appSettingsProvider.future);

      if (!ajustes.notificationsEnabled) {
        await servicio.sincronizar(
          const <NotificationItem>[],
          soloMisiones: soloMisiones,
        );
        return;
      }

      final List<AlertSound> sonidos = await _ref.read(alertSoundsProvider.future);
      final Translator traductor = await _ref.read(translatorProvider.future);

      final List<MissionPlan> planes = ReminderPlanner.planificarTareas(
        tareas,
        ahora: DateTime.now(),
      );

      final List<NotificationItem> items = <NotificationItem>[
        for (final MissionPlan plan in planes)
          for (final PlannedAlert alerta in plan.alertas)
            _redactar(plan.tarea, alerta, sonidos, traductor),
      ];

      await servicio.sincronizar(items, soloMisiones: soloMisiones);
    } catch (e, s) {
      debugPrint('❌ [NOTIFICATIONS] // Fallo al sincronizar: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  NotificationItem _redactar(
    Task tarea,
    PlannedAlert alerta,
    List<AlertSound> sonidos,
    Translator t,
  ) {
    switch (alerta.tipo) {
      case AlertKind.recordatorio:
        final String tiempo = ReminderPlanner.formatearRestante(alerta.restante);
        return NotificationItem(
          id: alerta.id,
          cuando: alerta.cuando,
          tipo: alerta.tipo,
          titulo: tarea.titulo,
          cuerpo: t
              .t(
                'notifications.status',
                fallback: 'La misión culmina en {time}',
              )
              .replaceAll('{time}', tiempo),
          modo: tarea.tipoAlarma,
        );
      case AlertKind.urgente:
        final String tiempo = ReminderPlanner.formatearRestante(
          alerta.restante,
          detallado: true,
        );
        return NotificationItem(
          id: alerta.id,
          cuando: alerta.cuando,
          tipo: alerta.tipo,
          titulo: t.t(
            'notifications.urgent_title',
            fallback: '⚠️ ¡Misión por terminar!',
          ),
          cuerpo: t
              .t(
                'notifications.urgent_body',
                fallback: '«{title}» culmina en {time}. ¡No lo dejes para después!',
              )
              .replaceAll('{title}', tarea.titulo)
              .replaceAll('{time}', tiempo),
          modo: tarea.tipoAlarma,
        );
      case AlertKind.finalizacion:
      case AlertKind.repeticion:
        final bool esRepeticion = alerta.tipo == AlertKind.repeticion;
        return NotificationItem(
          id: alerta.id,
          cuando: alerta.cuando,
          tipo: alerta.tipo,
          titulo: tarea.titulo,
          // Las repeticiones usan el mismo modo, sonido y duración que la
          // alerta final; cambia solo el texto.
          cuerpo: esRepeticion
              ? t
                  .t(
                    'notifications.repeat_body',
                    fallback: 'Sigue pendiente · repetición {n} de {total}',
                  )
                  .replaceAll('{n}', '${alerta.numero}')
                  .replaceAll('{total}', '${alerta.total}')
              : t.t(
                  'notifications.done_body',
                  fallback: 'El plazo de la misión ha culminado.',
                ),
          modo: tarea.tipoAlarma,
          // Un audio propio tiene prioridad sobre los de assets/audio.
          sonido: tarea.sonidoUri.isEmpty
              ? resolverSonido(sonidos, tarea.sonido)
              : null,
          sonidoUri: tarea.sonidoUri.isEmpty ? null : tarea.sonidoUri,
          sonidoNombre: tarea.sonidoNombre.isEmpty ? null : tarea.sonidoNombre,
          duracionSeg: tarea.duracionSeg,
        );
    }
  }
}