// lib/features/alarms/data/services/custom_sound_service.dart
import 'package:flutter/services.dart';

/// Audio propio ya importado y listo para usarse en una notificación.
class CustomSound {
  const CustomSound({required this.uri, required this.nombre});

  /// URI `content://` de MediaStore, legible por el sistema.
  final String uri;

  /// Nombre visible (el del archivo elegido).
  final String nombre;
}

class CustomSoundException implements Exception {
  const CustomSoundException(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'CustomSoundException: $mensaje';
}

/// Puente con `MainActivity.kt`: abre el selector de archivos de Android y
/// copia el audio elegido a MediaStore (Alarms/RecordApp), porque el sonido de
/// una notificación lo reproduce el sistema y necesita poder leer el archivo.
class CustomSoundService {
  const CustomSoundService();

  static const MethodChannel _canal =
      MethodChannel('com.alessandro.recordapp/sonidos');

  /// Devuelve null si el usuario cancela. Lanza [CustomSoundException] si la
  /// importación falla (Android < 10, archivo ilegible, etc.).
  Future<CustomSound?> elegir() async {
    try {
      final Map<String, String>? r =
          await _canal.invokeMapMethod<String, String>('elegirSonido');
      if (r == null) return null;
      final String? uri = r['uri'];
      if (uri == null || uri.isEmpty) return null;
      return CustomSound(uri: uri, nombre: r['nombre'] ?? 'Audio propio');
    } on PlatformException catch (e) {
      throw CustomSoundException(e.message ?? 'No se pudo importar el audio.');
    } on MissingPluginException {
      throw const CustomSoundException(
        'La función no está disponible en esta compilación.',
      );
    }
  }
}