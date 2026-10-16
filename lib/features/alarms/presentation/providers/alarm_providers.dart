// lib/features/alarms/presentation/providers/alarm_providers.dart
import 'package:recordapp/features/alarms/data/services/alert_audio_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_providers.g.dart';

/// Reproductor para escuchar los sonidos en el editor. La alerta real de una
/// misión no pasa por aquí: la entrega siempre la notificación del sistema.
@Riverpod(keepAlive: true)
AlertAudioService alertAudioService(Ref ref) {
  final AlertAudioService servicio = AlertAudioService();
  ref.onDispose(servicio.liberar);
  return servicio;
}