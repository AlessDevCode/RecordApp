// lib/features/alarms/data/services/alert_audio_service.dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';

/// Reproduce audios dentro de la app: previsualización en el editor y alerta
/// de finalización cuando la app está en primer plano.
///
/// Todo el audio sale por el **stream de alarmas de Android**
/// (`AndroidUsageType.alarm`): suena con el volumen de ALARMA del sistema,
/// independiente del volumen multimedia, y puede cortar la música de otras
/// apps (audio focus `gain`).
///
/// Mientras una alarma está sonando, el servicio considera que SOLO el
/// usuario puede detenerla (llamando a [detener], p. ej. con el botón
/// SILENCIAR). Si el reproductor se pausa o se detiene por otra causa
/// (cambio de foco de audio, un evento del sistema…), se reanuda
/// automáticamente, y cada cambio de estado queda en la consola para poder
/// diagnosticar qué lo provocó.
///
/// Nota: esto NO sube el volumen del sistema ni intercepta las teclas
/// físicas (eso lo gestiona Android).
class AlertAudioService {
  AlertAudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _suscripcion = _player.onPlayerStateChanged.listen(_alCambiarEstado);
  }

  /// Atributos de audio de una alarma. `sonification` es el tipo de contenido
  /// recomendado para tonos de aviso (ni música ni voz).
  static final AudioContext _contextoAlarma = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );

  /// Máximo de reanudaciones automáticas por alarma, para no entrar en un
  /// bucle si algo del sistema insiste en detener el audio.
  static const int _maxReintentos = 3;

  final AudioPlayer _player;
  StreamSubscription<PlayerState>? _suscripcion;

  /// true mientras la alarma debe seguir sonando (hasta que termine el audio
  /// o el usuario llame a [detener]).
  bool _debeSonar = false;
  int _reintentos = 0;
  Source? _fuenteActual;

  /// Reproduce [sonido] desde el inicio por el stream de alarmas. Si algo
  /// falla, lo registra con detalle en consola y relanza la excepción para
  /// que el llamador decida.
  Future<void> reproducir(AlertSound sonido) async {
    debugPrint(
      '🔊 [AUDIO] // Reproduciendo "${sonido.fileName}" por el stream de '
      'ALARMA (AssetSource: ${sonido.playerSource})',
    );
    try {
      // El stop() propio no debe interpretarse como una interrupción externa.
      _debeSonar = false;
      _reintentos = 0;
      await _player.stop();

      final Source fuente = AssetSource(sonido.playerSource);
      _fuenteActual = fuente;

      // El contexto se aplica antes de cada play(): así se garantiza que el
      // audio nunca caiga en el stream multimedia por defecto.
      await _player.setAudioContext(_contextoAlarma);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);

      _debeSonar = true;
      await _player.play(fuente);
      debugPrint('🔊 [AUDIO] // play() OK. Estado: ${_player.state}');
    } catch (e, s) {
      _debeSonar = false;
      debugPrint('❌ [AUDIO] // Falló la reproducción de "${sonido.fileName}": $e');
      debugPrintStack(stackTrace: s, maxFrames: 6);
      rethrow;
    }
  }

  /// Detención pedida por el usuario (SILENCIAR) o por la app.
  Future<void> detener() async {
    _debeSonar = false;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('❌ [AUDIO] // Error al detener: $e');
    }
  }

  void _alCambiarEstado(PlayerState estado) {
    debugPrint(
      '🔊 [AUDIO] // Estado del reproductor: $estado '
      '(debeSonar=$_debeSonar, reintentos=$_reintentos)',
    );
    if (!_debeSonar) return;

    if (estado == PlayerState.completed) {
      // El audio terminó por sí solo: fin normal.
      _debeSonar = false;
      return;
    }

    final bool interrumpido =
        estado == PlayerState.paused || estado == PlayerState.stopped;
    if (!interrumpido) return;

    final Source? fuente = _fuenteActual;
    if (fuente == null) return;

    if (_reintentos >= _maxReintentos) {
      debugPrint(
        '⚠️ [AUDIO] // Interrumpido $_maxReintentos veces por el sistema: '
        'no se insiste más.',
      );
      _debeSonar = false;
      return;
    }

    _reintentos++;
    debugPrint(
      '⚠️ [AUDIO] // La alarma se interrumpió sin que el usuario la detuviera '
      '(estado=$estado). Reanudando (intento $_reintentos/$_maxReintentos)…',
    );
    unawaited(_reanudar(fuente));
  }

  Future<void> _reanudar(Source fuente) async {
    try {
      await _player.setAudioContext(_contextoAlarma);
      await _player.play(fuente);
    } catch (e, s) {
      debugPrint('❌ [AUDIO] // No se pudo reanudar la alarma: $e');
      debugPrintStack(stackTrace: s, maxFrames: 6);
    }
  }

  Future<void> liberar() async {
    _debeSonar = false;
    await _suscripcion?.cancel();
    _suscripcion = null;
    await _player.dispose();
  }
}