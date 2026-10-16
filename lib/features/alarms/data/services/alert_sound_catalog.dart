// lib/features/alarms/data/services/alert_sound_catalog.dart
import 'package:flutter/services.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';

/// Detecta e indexa los audios de `assets/audio/` leyendo el AssetManifest.
/// Requiere que `- assets/audio/` esté declarado en `pubspec.yaml`.
class AlertSoundCatalog {
  const AlertSoundCatalog();

  static const String _prefijo = 'assets/audio/';
  static const Set<String> _extensiones = <String>{
    '.mp3',
    '.wav',
    '.ogg',
    '.m4a',
    '.aac',
  };

  Future<List<AlertSound>> cargar({AssetBundle? bundle}) async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      bundle ?? rootBundle,
    );

    final List<AlertSound> sonidos = manifest
        .listAssets()
        .map(Uri.decodeFull)
        .where(_esAudioDirecto)
        .map(AlertSound.fromAssetPath)
        .toList()
      ..sort(
        (AlertSound a, AlertSound b) =>
            a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()),
      );
    return sonidos;
  }

  static bool _esAudioDirecto(String ruta) {
    if (!ruta.startsWith(_prefijo)) return false;
    final String resto = ruta.substring(_prefijo.length);
    if (resto.isEmpty || resto.contains('/')) return false;
    final int punto = resto.lastIndexOf('.');
    if (punto < 0) return false;
    return _extensiones.contains(resto.substring(punto).toLowerCase());
  }
}
