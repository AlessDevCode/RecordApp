// lib/features/tasks/presentation/widgets/task_card.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recordapp/core/i18n/translation_extension.dart';
import 'package:recordapp/core/router/app_router.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/models/time_format_pref.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/alarm_type.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/models/task_category.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';
import 'package:recordapp/features/tasks/domain/services/smart_tagger.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';
import 'package:recordapp/features/tasks/presentation/providers/clock_provider.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({required this.task, super.key});

  final Task task;

  String _emojiCategoria() {
    final String nombre = task.categoriaId.toUpperCase().trim();
    for (final TaskCategory categoria in SmartTagger.categorias) {
      if (categoria.nombre == nombre) return categoria.emoji;
    }
    return '📌';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSettings settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();

    // Se actualiza cada minuto: el estado CRÍTICO de una rutina termina solo
    // al acabar su ventana y la tarjeta pasa a la siguiente ocurrencia.
    final DateTime ahora = ref.watch(clockProvider).value ?? DateTime.now();
    final bool vencida = RoutineService.estaVencida(task, ahora: ahora);
    final bool esRutina = task.esRutina;

    // En una rutina el check significa "hecha hoy" (o terminada del todo).
    final bool marcada = esRutina
        ? (task.completada || RoutineService.hechaHoy(task, ahora: ahora))
        : task.completada;

    final bool formato24h = settings.timeFormat == TimeFormatPref.h24;

    // Una rutina muestra siempre su PRÓXIMA ocurrencia pendiente, con la hora
    // que le corresponde a ese día (la de su bloque, o la principal).
    final DateTime? proxima =
        esRutina ? RoutineService.proximaEjecucion(task, ahora: ahora) : null;

    final String textoFecha;
    if (esRutina) {
      if (proxima == null) {
        textoFecha = ref.tr('card.no_next', 'Sin próximas ocurrencias');
      } else {
        final String fechaProxima = TimeFormatter.fechaDb(proxima);
        final String hoy = TimeFormatter.fechaDb(ahora);
        final String manana = TimeFormatter.fechaDb(
          DateTime(ahora.year, ahora.month, ahora.day + 1),
        );
        final String dia = fechaProxima == hoy
            ? ref.tr('card.today', 'Hoy')
            : fechaProxima == manana
                ? ref.tr('card.tomorrow', 'Mañana')
                : TimeFormatter.formatearFecha(
                    fechaProxima,
                    patron: settings.dateFormat,
                  );
        final String hora = TimeFormatter.formatearHora(
          TimeFormatter.horaDb(proxima),
          formato24h: formato24h,
        );
        textoFecha = '${ref.tr('card.next', 'Próxima')}: $dia · $hora';
      }
    } else {
      textoFecha = <String>[
        if (task.fechaLimite.trim().isNotEmpty)
          TimeFormatter.formatearFecha(
            task.fechaLimite,
            patron: settings.dateFormat,
          ),
        if (task.horaLimite.trim().isNotEmpty)
          TimeFormatter.formatearHora(
            task.horaLimite,
            formato24h: formato24h,
          ),
      ].join(' · ');
    }
    final bool tieneProgramacion = esRutina || task.fechaLimite.trim().isNotEmpty;

    final List<String> etiquetasDias = ref
        .tr('editor.weekdays_short', RoutineService.etiquetasDiasPorDefecto)
        .split(',');
    final String resumenRutina = esRutina
        ? RoutineService.resumenFrecuencia(
            task,
            etiquetasDias: etiquetasDias,
            textoFechas: (int n) =>
                '$n ${ref.tr('card.dates', 'fechas')}',
          )
        : '';

    final int? id = task.id;

    final TextStyle? estiloTitulo = theme.textTheme.titleMedium?.copyWith(
      decoration: marcada ? TextDecoration.lineThrough : null,
      color: marcada ? scheme.onSurfaceVariant : scheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    final TextStyle? estiloDescripcion = theme.textTheme.bodyMedium?.copyWith(
      decoration: marcada ? TextDecoration.lineThrough : null,
      color: scheme.onSurfaceVariant,
    );

    return Dismissible(
      key: ValueKey<String>('task_${task.id}_${task.titulo}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) {
        if (id != null) {
          unawaited(ref.read(taskListProvider.notifier).eliminarTarea(id));
        }
      },
      child: AnimatedOpacity(
        opacity: marcada ? 0.65 : 1,
        duration: const Duration(milliseconds: 200),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: vencida ? scheme.error : scheme.outlineVariant,
              width: vencida ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => unawaited(
              context.push<void>(AppRoutes.editor, extra: task),
            ),
            child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox(
                  value: marcada,
                  onChanged: id == null
                      ? null
                      : (bool? valor) {
                          unawaited(
                            ref
                                .read(taskListProvider.notifier)
                                .cambiarEstadoCompletado(
                                  id,
                                  completada: valor ?? false,
                                ),
                          );
                        },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 8),
                  child: Text(
                    _emojiCategoria(),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(task.titulo, style: estiloTitulo),
                        if (task.descripcion.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              task.descripcion,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: estiloDescripcion,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(
                              ref.trCategoria(task.categoriaId),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (textoFecha.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: vencida
                                        ? scheme.error
                                        : scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    textoFecha,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: vencida
                                          ? scheme.error
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            if (esRutina)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.repeat,
                                    size: 14,
                                    color: scheme.tertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    resumenRutina,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            if (tieneProgramacion)
                              Icon(
                                switch (task.tipoAlarma) {
                                  AlarmType.sonido => Icons.volume_up_outlined,
                                  AlarmType.vibracion => Icons.vibration,
                                  AlarmType.silencioso =>
                                    Icons.volume_off_outlined,
                                },
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            if (vencida)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  ref.tr('card.overdue', 'CRÍTICO'),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: ref.tr('card.delete', 'Eliminar misión'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: id == null
                      ? null
                      : () {
                          unawaited(
                            ref
                                .read(taskListProvider.notifier)
                                .eliminarTarea(id),
                          );
                        },
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}