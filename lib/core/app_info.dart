// lib/core/app_info.dart

/// Datos de la app que se muestran en pantalla.
///
/// Mantén [version] igual a la del `pubspec.yaml` (la parte antes del `+`:
/// `version: 1.0.0+1` → `1.0.0`).
abstract final class AppInfo {
  static const String name = 'RecordApp';
  static const String version = '1.0.0';
}