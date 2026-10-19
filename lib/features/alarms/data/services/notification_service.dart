// lib/features/alarms/data/services/notification_service.dart
import 'dart:typed_data' show Int32List;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';
import 'package:recordapp/features/alarms/domain/services/reminder_planner.dart';
import 'package:recordapp/features/tasks/domain/models/alarm_type.dart';
import 'package:timezone/timezone.dart' as tz;

/// Una notificación ya redactada y lista para programar.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.cuando,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.modo,
    this.sonido,
    this.sonidoUri,
    this.sonidoNombre,
    this.duracionSeg = 0,
  });

  final int id;
  final DateTime cuando;
  final AlertKind tipo;
  final String titulo;
  final String cuerpo;

  /// Solo relevante para [AlertKind.finalizacion] y [AlertKind.repeticion].
  final AlarmType modo;

  /// Sonido incluido en assets/audio (se usa si [sonidoUri] es null).
  final AlertSound? sonido;

  /// Audio propio del usuario (URI de MediaStore). Tiene prioridad.
  final String? sonidoUri;
  final String? sonidoNombre;

  /// 0 = suena una vez; mayor que 0 = se repite hasta completar esos segundos.
  final int duracionSeg;
}

/// Envoltorio de `flutter_local_notifications` (solo Android).
///
/// Toda alerta de finalización la entrega la notificación programada, con la
/// app abierta, en segundo plano o cerrada. Para silenciarla, el usuario toca
/// o descarta la notificación.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _icono = '@drawable/ic_stat_mission';

  /// Los canales de Android son INMUTABLES una vez creados: si uno se creó
  /// con una configuración defectuosa, queda así para siempre. Subir esta
  /// versión crea canales nuevos con la configuración correcta.
  static const String _vCanal = 'v2';

  /// Id de la notificación permanente de estado. Está fuera del rango de las
  /// misiones (idMision * 100), así que ni la programación ni la cancelación
  /// de misiones la tocan.
  static const int _idEstadoPermanente = 2147480100;

  /// Vibración de la alerta final: espera 0 ms y vibra 3000 ms.
  static final Int64List _patronTresSegundos = Int64List.fromList(
    <int>[0, 3000],
  );

  /// FLAG_INSISTENT (4): el sonido de la notificación se repite en bucle hasta
  /// que la notificación se descarta o caduca (`timeoutAfter`).
  static final Int32List _flagInsistente = Int32List.fromList(<int>[4]);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _inicializado = false;

  /// Último texto publicado en la notificación permanente (para no volver a
  /// publicar lo mismo) y si ya se quitó en esta sesión.
  String? _ultimoEstado;
  bool _estadoOculto = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icono),
        ),
      );
      _inicializado = true;
    } catch (e, s) {
      debugPrint('❌ [NOTIFICATIONS] // Falló initialize(): $e');
      debugPrintStack(stackTrace: s, maxFrames: 6);
      rethrow;
    }
  }

  /// Pide permiso de notificaciones (diálogo del sistema en Android 13+) y, si
  /// hace falta, el de alarmas exactas (Android 12). Devuelve si las
  /// notificaciones quedaron permitidas.
  ///
  /// Requiere `POST_NOTIFICATIONS` en el AndroidManifest: sin él, Android 13+
  /// no muestra el diálogo y la petición devuelve false sin avisar.
  Future<bool> solicitarPermisos() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? android = _android;
      if (android == null) {
        debugPrint('❌ [NOTIFICATIONS] // Implementación Android no disponible.');
        return false;
      }

      bool notificaciones = await android.areNotificationsEnabled() ?? false;
      if (!notificaciones) {
        notificaciones =
            await android.requestNotificationsPermission() ?? false;
      }

      final bool exactas = await android.canScheduleExactNotifications() ?? true;
      if (!exactas) {
        await android.requestExactAlarmsPermission();
      }

      if (!notificaciones) {
        debugPrint(
          '⚠️ [NOTIFICATIONS] // Permiso DENEGADO. Actívalo en Ajustes > '
          'Apps > RecordApp > Notificaciones.',
        );
      }
      return notificaciones;
    } catch (e, s) {
      debugPrint('❌ [NOTIFICATIONS] // Error al pedir permisos: $e');
      debugPrintStack(stackTrace: s, maxFrames: 6);
      return false;
    }
  }

  /// Crea por adelantado los canales de misión (los de sonido, uno por archivo
  /// detectado en assets/audio). Los de audio propio se crean solos la primera
  /// vez que se muestra su notificación.
  Future<void> crearCanales(List<AlertSound> sonidos) async {
    final AndroidFlutterLocalNotificationsPlugin? android = _android;
    if (android == null) return;

    final List<AndroidNotificationChannel> canales = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'mission_reminders_$_vCanal',
        'Recordatorios de misión',
        description: 'Estado de las misiones en curso',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
      ),
      AndroidNotificationChannel(
        'status_persistent_$_vCanal',
        'Estado de RecordApp',
        description: 'Muestra tu próxima misión o alarma en la barra de estado',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
      AndroidNotificationChannel(
        'mission_urgent_$_vCanal',
        'Misiones por terminar',
        description: 'Aviso frecuente en las últimas 6 horas',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      ),
      AndroidNotificationChannel(
        'mission_done_silent_$_vCanal',
        'Fin de misión (silencioso)',
        description: 'Aviso visual al culminar el plazo',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      ),
      AndroidNotificationChannel(
        'mission_done_vibration_$_vCanal',
        'Fin de misión (vibración)',
        description: 'Vibra 3 segundos al culminar el plazo',
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
        vibrationPattern: _patronTresSegundos,
      ),
      AndroidNotificationChannel(
        'mission_done_sound_default_$_vCanal',
        'Fin de misión (sonido)',
        description: 'Suena al culminar el plazo',
        importance: Importance.max,
        playSound: true,
        enableVibration: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      for (final AlertSound s in sonidos)
        AndroidNotificationChannel(
          'mission_done_sound_${s.rawResourceName}_$_vCanal',
          'Fin de misión: ${s.label}',
          description: 'Suena al culminar el plazo',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(s.rawResourceName),
          enableVibration: false,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
    ];

    for (final AndroidNotificationChannel canal in canales) {
      try {
        await android.createNotificationChannel(canal);
      } catch (e) {
        debugPrint('❌ [NOTIFICATIONS] // No se pudo crear el canal ${canal.id}: $e');
      }
    }
  }

  Future<AndroidScheduleMode> _modoDeProgramacion() async {
    final bool exactas =
        await _android?.canScheduleExactNotifications() ?? false;
    return exactas
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Deja programadas exactamente [items]. Cancela las pendientes que ya no
  /// forman parte del plan. Con [soloMisiones] solo toca esas misiones; con
  /// null toca todas. Reprogramar un mismo id reemplaza la alarma anterior.
  Future<void> sincronizar(
    List<NotificationItem> items, {
    Set<int>? soloMisiones,
  }) async {
    await inicializar();

    final Set<int> idsPlan = items.map((NotificationItem i) => i.id).toSet();
    final List<PendingNotificationRequest> pendientes =
        await _plugin.pendingNotificationRequests();

    for (final PendingNotificationRequest p in pendientes) {
      if (idsPlan.contains(p.id)) continue;
      if (soloMisiones != null &&
          !soloMisiones.contains(ReminderPlanner.idMisionDe(p.id))) {
        continue;
      }
      await _plugin.cancel(id: p.id);
    }

    if (items.isEmpty) return;
    final AndroidScheduleMode modo = await _modoDeProgramacion();
    for (final NotificationItem item in items) {
      try {
        await _plugin.zonedSchedule(
          id: item.id,
          title: item.titulo,
          body: item.cuerpo,
          scheduledDate: _aUtc(item.cuando),
          notificationDetails: _detalles(item),
          androidScheduleMode: modo,
        );
      } catch (e, s) {
        debugPrint('❌ [NOTIFICATIONS] // No se pudo programar id=${item.id}: $e');
        debugPrintStack(stackTrace: s, maxFrames: 6);
      }
    }
  }

  /// Publica o actualiza la notificación permanente de estado (la misma, con
  /// un id fijo): no se puede descartar al deslizar, no se cierra al tocarla
  /// y, con importancia baja, se actualiza sin sonar ni vibrar.
  Future<void> mostrarEstadoPermanente({
    required String titulo,
    required String cuerpo,
  }) async {
    final String huella = '$titulo\n$cuerpo';
    if (huella == _ultimoEstado) return;

    await inicializar();
    try {
      if (!(await _android?.areNotificationsEnabled() ?? true)) {
        debugPrint(
          '⚠️ [STATUS] // Android tiene las notificaciones de RecordApp '
          'desactivadas: la notificación fija no se verá.',
        );
      }
      await _plugin.show(
        id: _idEstadoPermanente,
        title: titulo,
        body: cuerpo,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'status_persistent_$_vCanal',
            'Estado de RecordApp',
            channelDescription:
                'Muestra tu próxima misión o alarma en la barra de estado',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: false,
            icon: _icono,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
            category: AndroidNotificationCategory.status,
            styleInformation: BigTextStyleInformation(cuerpo),
          ),
        ),
      );
      _ultimoEstado = huella;
      _estadoOculto = false;
      debugPrint('📌 [STATUS] // Notificación fija publicada: "$titulo"');
    } catch (e, s) {
      debugPrint('❌ [NOTIFICATIONS] // No se pudo mostrar el estado fijo: $e');
      debugPrintStack(stackTrace: s, maxFrames: 6);
    }
  }

  /// Olvida lo último publicado, para que la próxima actualización vuelva a
  /// publicar aunque el texto sea el mismo (p. ej. tras conceder el permiso de
  /// notificaciones, cuando una publicación anterior no llegó a mostrarse).
  void invalidarEstadoPermanente() => _ultimoEstado = null;

  /// Quita la notificación permanente de estado. Se llama siempre la primera
  /// vez de cada sesión, porque pudo quedar publicada de la ejecución anterior.
  Future<void> ocultarEstadoPermanente() async {
    if (_estadoOculto) return;
    await inicializar();
    try {
      await _plugin.cancel(id: _idEstadoPermanente);
      _estadoOculto = true;
      _ultimoEstado = null;
      debugPrint('📌 [STATUS] // Notificación fija quitada.');
    } catch (e) {
      debugPrint('❌ [NOTIFICATIONS] // No se pudo quitar el estado fijo: $e');
    }
  }

  /// Cancela todo lo de una misión: alarmas pendientes y notificaciones que
  /// ya estén en la bandeja (si estaba sonando, el sonido se corta).
  Future<void> cancelarMision(int idMision) async {
    await inicializar();
    final int base = ReminderPlanner.idBase(idMision);
    bool enRango(int id) =>
        id >= base && id < base + ReminderPlanner.idsPorMision;

    final List<PendingNotificationRequest> pendientes =
        await _plugin.pendingNotificationRequests();
    for (final PendingNotificationRequest p in pendientes) {
      if (enRango(p.id)) await _plugin.cancel(id: p.id);
    }

    final List<ActiveNotification> activas =
        await _plugin.getActiveNotifications();
    for (final ActiveNotification a in activas) {
      final int? id = a.id;
      if (id != null && enRango(id)) await _plugin.cancel(id: id);
    }
  }

  // El plugin necesita un TZDateTime, pero las alarmas no recurrentes se
  // fijan por instante absoluto. Pasar el instante en UTC evita depender de
  // la zona horaria local (y de otro paquete para detectarla).
  tz.TZDateTime _aUtc(DateTime fecha) {
    final DateTime u = fecha.toUtc();
    return tz.TZDateTime.utc(
      u.year,
      u.month,
      u.day,
      u.hour,
      u.minute,
      u.second,
    );
  }

  NotificationDetails _detalles(NotificationItem item) {
    final AndroidNotificationDetails android = switch (item.tipo) {
      AlertKind.recordatorio => AndroidNotificationDetails(
          'mission_reminders_$_vCanal',
          'Recordatorios de misión',
          channelDescription: 'Estado de las misiones en curso',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          icon: _icono,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(item.cuerpo),
        ),
      AlertKind.urgente => AndroidNotificationDetails(
          'mission_urgent_$_vCanal',
          'Misiones por terminar',
          channelDescription: 'Aviso frecuente en las últimas 6 horas',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          icon: _icono,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(item.cuerpo),
        ),
      // Una repetición suena y vibra exactamente como la alerta final.
      AlertKind.finalizacion => _detallesFinalizacion(item),
      AlertKind.repeticion => _detallesFinalizacion(item),
    };
    return NotificationDetails(android: android);
  }

  /// Identificador de canal estable para un audio propio: el id numérico de
  /// MediaStore (último tramo de `content://media/external/audio/media/123`).
  String _idSeguro(String uri) {
    final String ultimo = uri.substring(uri.lastIndexOf('/') + 1);
    return ultimo.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  }

  AndroidNotificationDetails _detallesFinalizacion(NotificationItem item) {
    final BigTextStyleInformation estilo = BigTextStyleInformation(item.cuerpo);

    switch (item.modo) {
      case AlarmType.silencioso:
        return AndroidNotificationDetails(
          'mission_done_silent_$_vCanal',
          'Fin de misión (silencioso)',
          channelDescription: 'Aviso visual al culminar el plazo',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          icon: _icono,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          category: AndroidNotificationCategory.alarm,
          styleInformation: estilo,
        );
      case AlarmType.vibracion:
        return AndroidNotificationDetails(
          'mission_done_vibration_$_vCanal',
          'Fin de misión (vibración)',
          channelDescription: 'Vibra 3 segundos al culminar el plazo',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: _patronTresSegundos,
          icon: _icono,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          category: AndroidNotificationCategory.alarm,
          styleInformation: estilo,
        );
      case AlarmType.sonido:
        final String? uri = item.sonidoUri;
        final AlertSound? s = item.sonido;
        final bool propio = uri != null && uri.isNotEmpty;

        // Un canal por sonido: en Android 8+ el sonido es inmutable por canal.
        final String idCanal;
        final String nombreCanal;
        final AndroidNotificationSound? sonidoCanal;
        if (propio) {
          idCanal = 'mission_done_custom_${_idSeguro(uri)}_$_vCanal';
          nombreCanal = 'Fin de misión: ${item.sonidoNombre ?? 'audio propio'}';
          sonidoCanal = UriAndroidNotificationSound(uri);
        } else if (s != null) {
          idCanal = 'mission_done_sound_${s.rawResourceName}_$_vCanal';
          nombreCanal = 'Fin de misión: ${s.label}';
          sonidoCanal = RawResourceAndroidNotificationSound(s.rawResourceName);
        } else {
          idCanal = 'mission_done_sound_default_$_vCanal';
          nombreCanal = 'Fin de misión (sonido)';
          sonidoCanal = null;
        }

        // Duración personalizada: el sonido se repite en bucle (INSISTENT) y
        // la notificación caduca a los N segundos, lo que corta el sonido.
        final bool conDuracion = item.duracionSeg > 0;

        return AndroidNotificationDetails(
          idCanal,
          nombreCanal,
          channelDescription: 'Suena al culminar el plazo',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: sonidoCanal,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: false,
          additionalFlags: conDuracion ? _flagInsistente : null,
          timeoutAfter: conDuracion ? item.duracionSeg * 1000 : null,
          icon: _icono,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          category: AndroidNotificationCategory.alarm,
          styleInformation: estilo,
        );
    }
  }
}