// lib/features/tasks/presentation/widgets/filters_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recordapp/core/i18n/translation_extension.dart';
import 'package:recordapp/features/tasks/domain/models/task_category.dart';
import 'package:recordapp/features/tasks/domain/models/task_filter_state.dart';
import 'package:recordapp/features/tasks/domain/models/task_status_filter.dart';
import 'package:recordapp/features/tasks/domain/services/smart_tagger.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';

/// Barra horizontal de filtros (estado y categoría), con scroll táctil.
class FiltersBar extends ConsumerWidget {
  const FiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TaskFilterState filtro = ref.watch(taskFilterProvider);
    final TaskFilter notifier = ref.read(taskFilterProvider.notifier);

    final bool hayFiltros =
        filtro.estados.isNotEmpty || filtro.categoria != null;

    Widget separado(Widget hijo) {
      return Padding(padding: const EdgeInsets.only(right: 8), child: hijo);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          separado(
            FilterChip(
              label: Text(ref.tr('filters.on_time', 'EN TIEMPO')),
              avatar: const Icon(Icons.check_circle_outline, size: 18),
              selected: filtro.estados.contains(TaskStatusFilter.enTiempo),
              onSelected: (_) =>
                  notifier.alternarEstado(TaskStatusFilter.enTiempo),
            ),
          ),
          separado(
            FilterChip(
              label: Text(ref.tr('filters.critical', 'CRÍTICO')),
              avatar: const Icon(Icons.warning_amber_rounded, size: 18),
              selected: filtro.estados.contains(TaskStatusFilter.critico),
              onSelected: (_) =>
                  notifier.alternarEstado(TaskStatusFilter.critico),
            ),
          ),
          separado(
            FilterChip(
              label: Text(ref.tr('filters.routines', 'RUTINAS')),
              avatar: const Icon(Icons.repeat, size: 18),
              selected: filtro.estados.contains(TaskStatusFilter.rutinas),
              onSelected: (_) =>
                  notifier.alternarEstado(TaskStatusFilter.rutinas),
            ),
          ),
          separado(
            FilterChip(
              label: Text(ref.tr('filters.completed', 'COMPLETADAS')),
              avatar: const Icon(Icons.task_alt, size: 18),
              selected: filtro.estados.contains(TaskStatusFilter.completadas),
              onSelected: (_) =>
                  notifier.alternarEstado(TaskStatusFilter.completadas),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(height: 24, child: VerticalDivider(width: 16)),
          ),
          for (final TaskCategory categoria in SmartTagger.categorias)
            separado(
              ChoiceChip(
                label: Text('${categoria.emoji} ${categoria.nombre}'),
                selected: filtro.categoria == categoria.nombre,
                onSelected: (bool seleccionada) =>
                    notifier.establecerCategoria(
                  seleccionada ? categoria.nombre : null,
                ),
              ),
            ),
          if (hayFiltros)
            separado(
              ActionChip(
                avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(ref.tr('filters.clear', 'Limpiar filtros')),
                onPressed: notifier.limpiar,
              ),
            ),
        ],
      ),
    );
  }
}