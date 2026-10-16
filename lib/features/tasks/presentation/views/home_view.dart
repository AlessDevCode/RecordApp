// lib/features/tasks/presentation/views/home_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recordapp/core/i18n/translation_extension.dart';
import 'package:recordapp/core/router/app_router.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/completed_entry.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/models/task_filter_state.dart';
import 'package:recordapp/features/tasks/domain/models/task_status_filter.dart';
import 'package:recordapp/features/tasks/domain/services/task_filter_service.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';
import 'package:recordapp/features/tasks/presentation/widgets/completed_tile.dart';
import 'package:recordapp/features/tasks/presentation/widgets/filters_bar.dart';
import 'package:recordapp/features/tasks/presentation/widgets/task_card.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Task>> tareasAsync = ref.watch(taskListProvider);
    final List<Task> filtradas = ref.watch(filteredTasksProvider);
    final TaskFilterState filtro = ref.watch(taskFilterProvider);
    final String usuario = ref.watch(
      appSettingsProvider.select(
        (AsyncValue<AppSettings> v) => v.value?.cyberUsername ?? '',
      ),
    );

    final bool hayFiltros =
        filtro.estados.isNotEmpty || filtro.categoria != null;

    // COMPLETADAS cambia la lista por el historial: misiones normales
    // finalizadas y ejecuciones marcadas de las rutinas.
    final bool verCompletadas =
        filtro.estados.contains(TaskStatusFilter.completadas);
    final List<CompletedEntry> historial = verCompletadas
        ? TaskFilterService.entradasCompletadas(
            tareasAsync.value ?? const <Task>[],
            categoria: filtro.categoria,
            soloRutinas: filtro.estados.contains(TaskStatusFilter.rutinas),
          )
        : const <CompletedEntry>[];
    final int cantidad = verCompletadas ? historial.length : filtradas.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              ref.tr('home.title', 'MISIONES'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (usuario.isNotEmpty)
              Text(
                usuario,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: ref.tr('home.settings', 'Configuración'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const FiltersBar(),
          const Divider(height: 1),
          Expanded(
            child: tareasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(ref.tr('home.error', 'No se pudieron cargar las misiones')),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(taskListProvider),
                      child: Text(ref.tr('home.retry', 'Reintentar')),
                    ),
                  ],
                ),
              ),
              data: (List<Task> _) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(taskListProvider.notifier).cargarTareas();
                  },
                  child: cantidad == 0
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: <Widget>[
                            const SizedBox(height: 96),
                            Icon(
                              hayFiltros
                                  ? Icons.filter_alt_off_outlined
                                  : Icons.inbox_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                verCompletadas
                                    ? ref.tr(
                                        'home.empty_completed',
                                        'Aún no hay misiones completadas',
                                      )
                                    : hayFiltros
                                    ? ref.tr(
                                        'home.empty_filtered',
                                        'Ninguna misión coincide con los filtros',
                                      )
                                    : ref.tr(
                                        'home.empty',
                                        'Sin misiones registradas',
                                      ),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                          itemCount: cantidad,
                          itemBuilder: (BuildContext context, int index) {
                            if (verCompletadas) {
                              final CompletedEntry entrada = historial[index];
                              return CompletedTile(
                                key: ValueKey<String>(
                                  'hist_${entrada.tarea.id}_'
                                  '${entrada.fecha ?? 'm'}',
                                ),
                                entrada: entrada,
                              );
                            }
                            return TaskCard(task: filtradas[index]);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(context.push<void>(AppRoutes.editor)),
        icon: const Icon(Icons.add),
        label: Text(ref.tr('home.new_task', 'Nueva misión')),
      ),
    );
  }
}