// lib/features/tasks/presentation/widgets/completed_tile.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recordapp/core/i18n/translation_extension.dart';
import 'package:recordapp/core/router/app_router.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/models/time_format_pref.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/completed_entry.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';

/// Fila de la pestaña COMPLETADAS: una misión normal finalizada o una
/// ejecución concreta del historial de una rutina, con su botón "Deshacer".
class CompletedTile extends ConsumerWidget {
  const CompletedTile({required this.entrada, super.key});

  final CompletedEntry entrada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSettings settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();
    final bool formato24h = settings.timeFormat == TimeFormatPref.h24;

    final Task tarea = entrada.tarea;
    final String? fecha = entrada.fecha;

    final String detalle;
    if (fecha != null) {
      // Ejecución de una rutina: fecha marcada y hora que tenía ese día.
      final DateTime? dia = DateTime.tryParse(fecha);
      final String hora = dia == null ? '' : RoutineService.horaDe(tarea, dia);
      detalle = <String>[
        '${ref.tr('completed.done_on', 'Hecha el')} '
            '${TimeFormatter.formatearFecha(fecha, patron: settings.dateFormat)}',
        if (hora.trim().isNotEmpty)
          TimeFormatter.formatearHora(hora, formato24h: formato24h),
      ].join(' · ');
    } else {
      detalle = <String>[
        ref.tr('completed.mission', 'Misión completada'),
        if (tarea.fechaLimite.trim().isNotEmpty)
          TimeFormatter.formatearFecha(
            tarea.fechaLimite,
            patron: settings.dateFormat,
          ),
      ].join(' · ');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(
          context.push<void>(AppRoutes.editor, extra: tarea),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: <Widget>[
              Icon(Icons.check_circle, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      tarea.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        if (entrada.esEjecucion) ...<Widget>[
                          Icon(Icons.repeat, size: 14, color: scheme.tertiary),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            detalle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.undo, size: 18),
                label: Text(ref.tr('completed.undo', 'Deshacer')),
                onPressed: () => _deshacer(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deshacer(WidgetRef ref) {
    final int? id = entrada.tarea.id;
    if (id == null) return;
    final TaskList lista = ref.read(taskListProvider.notifier);
    final String? fecha = entrada.fecha;
    if (fecha != null) {
      unawaited(lista.deshacerEjecucion(id, fecha));
    } else {
      unawaited(lista.cambiarEstadoCompletado(id, completada: false));
    }
  }
}