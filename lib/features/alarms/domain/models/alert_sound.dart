// lib/features/alarms/domain/models/alert_sound.dart

/// Un archivo de audio detectado en `assets/audio/`.
class AlertSound {
  const AlertSound({required this.fileName, required this.assetPath});

  /// Crea el modelo a partir de la ruta completa del asset
  /// (ej. `assets/audio/alert.mp3`).
  factory AlertSound.fromAssetPath(String assetPath) {
    return AlertSound(
      assetPath: assetPath,
      fileName: assetPath.substring(assetPath.lastIndexOf('/') + 1),
    );
  }

  /// Nombre con extensión (ej. `alert.mp3`). Es lo que se guarda en la tarea.
  final String fileName;

  /// Ruta completa del asset (ej. `assets/audio/alert.mp3`).
  final String assetPath;

  String get _baseName {
    final int punto = fileName.lastIndexOf('.');
    return punto <= 0 ? fileName : fileName.substring(0, punto);
  }

  String get _extension {
    final int punto = fileName.lastIndexOf('.');
    return punto <= 0 ? '' : fileName.substring(punto + 1).toLowerCase();
  }

  /// Ruta para `AssetSource` de audioplayers (relativa a `assets/`).
  String get playerSource => assetPath.startsWith('assets/')
      ? assetPath.substring('assets/'.length)
      : assetPath;

  /// Nombre legible para el selector: `alerta_neon.mp3` -> `Alerta neon`.
  String get label {
    final String limpio = _baseName.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (limpio.isEmpty) return fileName;
    return limpio[0].toUpperCase() + limpio.substring(1);
  }

  /// Nombre del recurso en `android/app/src/main/res/raw/` (sin extensión).
  ///
  /// IMPORTANTE: debe coincidir exactamente con `rawName()` del script
  /// `android/app/sync_audio_raw.gradle.kts`, que copia los audios allí.
  /// Regla: minúsculas, todo carácter fuera de [a-z0-9_] pasa a `_`,
  /// prefijo `s_` si no empieza por letra, y se añade `_<extensión>` para
  /// que `alert.mp3` y `alert.wav` no colisionen.
  String get rawResourceName {
    final String base = _baseName.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '_',
        );
    final String seguro = RegExp(r'^[a-z]').hasMatch(base) ? base : 's_$base';
    return '${seguro}_$_extension';
  }

  @override
  bool operator ==(Object other) =>
      other is AlertSound && other.assetPath == assetPath;

  @override
  int get hashCode => assetPath.hashCode;
}

/// Devuelve el sonido de [nombreArchivo] si existe; si no, el predeterminado
/// (`alert.mp3` si está, o el primero de la lista). Null si no hay sonidos.
AlertSound? resolverSonido(List<AlertSound> sonidos, String nombreArchivo) {
  if (sonidos.isEmpty) return null;
  for (final AlertSound s in sonidos) {
    if (s.fileName == nombreArchivo) return s;
  }
  for (final AlertSound s in sonidos) {
    if (s.fileName == 'alert.mp3') return s;
  }
  return sonidos.first;
}
