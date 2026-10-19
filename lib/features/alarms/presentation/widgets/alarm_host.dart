// lib/features/alarms/presentation/widgets/alarm_host.dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recordapp/features/alarms/data/services/notification_service.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';
import 'package:recordapp/features/alarms/presentation/providers/notification_providers.dart';
import 'package:recordapp/features/alarms/presentation/providers/persistent_status_provider.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/presentation/providers/clock_provider.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';

/// Envuelve la app y deja listas las notificaciones: canales, permisos y
/// programación de todas las misiones. No muestra nada en pantalla: las
/// alertas se entregan y se silencian únicamente desde la notificación nativa.
///
/// También mantiene al día la notificación fija de estado (si está activada en
/// preferencias): se refresca cada minuto con el `clockProvider`, al cambiar
/// las misiones, al cambiar los ajustes y al volver a la app.
class AlarmHost extends ConsumerStatefulWidget {
  const AlarmHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AlarmHost> createState() => _AlarmHostState();
}

class _AlarmHostState extends ConsumerState<AlarmHost>
    with WidgetsBindingObserver {
  bool _sincronizando = false;
  bool _pendiente = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_arrancar());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app se renueva la ventana de recordatorios y se
    // recupera cualquier cambio de permisos o de hora del sistema.
    if (state == AppLifecycleState.resumed) {
      unawaited(_sincronizar());
      unawaited(_actualizarEstado());
    }
  }

  /// Refresca la notificación fija de estado (o la quita si está desactivada).
  Future<void> _actualizarEstado() {
    return ref.read(persistentStatusUpdaterProvider).actualizar();
  }

  Future<void> _arrancar() async {
    final AppSettings ajustes = await ref.read(appSettingsProvider.future);
    if (!mounted) return;

    final NotificationService servicio = ref.read(notificationServiceProvider);
    await servicio.inicializar();

    // Canales creados desde el arranque (uno por sonido de assets/audio).
    final List<AlertSound> sonidos = await ref.read(alertSoundsProvider.future);
    await servicio.crearCanales(sonidos);
    if (!mounted) return;

    if (ajustes.notificationsEnabled || ajustes.persistentNotification) {
      await servicio.solicitarPermisos();
      servicio.invalidarEstadoPermanente();
    }
    if (!mounted) return;
    await _sincronizar();
    if (!mounted) return;
    await _actualizarEstado();
  }

  /// Evita ejecuciones solapadas: si llega otra petición mientras se
  /// sincroniza, se repite una vez al terminar.
  Future<void> _sincronizar() async {
    if (_sincronizando) {
      _pendiente = true;
      return;
    }
    _sincronizando = true;
    try {
      do {
        _pendiente = false;
        final List<Task> tareas = await ref.read(taskListProvider.future);
        if (!mounted) return;
        await ref
            .read(missionNotificationSchedulerProvider)
            .sincronizarTodas(tareas);
      } while (_pendiente && mounted);
    } finally {
      _sincronizando = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cada minuto (ClockProvider) y cada vez que cambian las misiones se
    // refresca la notificación fija de estado. Escuchar aquí mantiene vivo el
    // reloj mientras la app esté abierta.
    ref.listen<AsyncValue<DateTime>>(clockProvider, (
      AsyncValue<DateTime>? previous,
      AsyncValue<DateTime> next,
    ) {
      unawaited(_actualizarEstado());
    });
    ref.listen<AsyncValue<List<Task>>>(taskListProvider, (
      AsyncValue<List<Task>>? previous,
      AsyncValue<List<Task>> next,
    ) {
      unawaited(_actualizarEstado());
    });

    // Cambió un ajuste: el interruptor de notificaciones o el idioma obligan a
    // reprogramar (y pedir permiso si se acaba de activar); el de la
    // notificación fija, el idioma y los formatos de fecha y hora obligan a
    // redibujarla.
    ref.listen<AsyncValue<AppSettings>>(appSettingsProvider, (
      AsyncValue<AppSettings>? previous,
      AsyncValue<AppSettings> next,
    ) {
      final AppSettings? antes = previous?.value;
      final AppSettings? ahora = next.value;
      if (antes == null || ahora == null) return;

      final bool cambioNotificaciones =
          antes.notificationsEnabled != ahora.notificationsEnabled;
      final bool cambioIdioma = antes.language != ahora.language;
      final bool cambioFijaOFormato =
          antes.persistentNotification != ahora.persistentNotification ||
              antes.dateFormat != ahora.dateFormat ||
              antes.timeFormat != ahora.timeFormat;
      if (!cambioNotificaciones && !cambioIdioma && !cambioFijaOFormato) {
        return;
      }

      unawaited(() async {
        final bool activaFija = ahora.persistentNotification &&
            !antes.persistentNotification;
        if ((cambioNotificaciones && ahora.notificationsEnabled) ||
            activaFija) {
          final NotificationService servicio =
              ref.read(notificationServiceProvider);
          await servicio.solicitarPermisos();
          servicio.invalidarEstadoPermanente();
        }
        if (cambioNotificaciones || cambioIdioma) {
          await _sincronizar();
        }
        await _actualizarEstado();
      }());
    });

    return widget.child;
  }
}