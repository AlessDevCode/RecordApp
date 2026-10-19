// lib/features/settings/presentation/widgets/about_header.dart
import 'package:flutter/material.dart';
import 'package:recordapp/core/app_info.dart';

/// Cabecera de la pantalla de ajustes: logo, nombre y versión de la app.
class AboutHeader extends StatelessWidget {
  const AboutHeader({super.key});

  /// Debe ser un archivo de una carpeta declarada en `flutter: assets:` del
  /// `pubspec.yaml` (aquí, `assets/icon/`).
  static const String _rutaLogo = 'assets/icon/verdio_logo.png';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              _rutaLogo,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              semanticLabel: AppInfo.name,
              // Si el archivo no existe o la ruta cambia, no rompe la pantalla.
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) =>
                  Icon(
                Icons.alarm,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppInfo.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'v${AppInfo.version}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}