// lib/features/alarms/presentation/widgets/alarm_host.dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recordapp/features/alarms/data/services/notification_service.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';
import 'package:recordapp/features/alarms/presentation/providers/notification_providers.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';

/// Envuelve la app y deja listas las notificaciones: canales, permisos y
/// programación de todas las misiones. No muestra nada en pantalla: las
/// alertas se entregan y se silencian únicamente desde la notificación nativa.
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
    }
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

    if (ajustes.notificationsEnabled) {
      await servicio.solicitarPermisos();
    }
    if (!mounted) return;
    await _sincronizar();
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
    // Cambió el interruptor de notificaciones o el idioma: hay que
    // reprogramar (y pedir permiso si se acaba de activar).
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
      if (!cambioNotificaciones && !cambioIdioma) return;

      unawaited(() async {
        if (cambioNotificaciones && ahora.notificationsEnabled) {
          await ref.read(notificationServiceProvider).solicitarPermisos();
        }
        await _sincronizar();
      }());
    });

    return widget.child;
  }
}