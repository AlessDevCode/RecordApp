// lib/features/tasks/domain/services/task_filter_service.dart
import 'package:recordapp/features/tasks/domain/models/completed_entry.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/models/task_status_filter.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';

abstract final class TaskFilterService {
  /// Filtra en memoria por estado, rutinas y categoría.
  /// - Crítico: vencida y no completada. En una rutina, vencida es que hoy le
  ///   tocaba, la hora ya pasó y no se marcó como hecha hoy.
  /// - En tiempo: no vencida y no completada.
  /// - Sin estados seleccionados se muestran todas.
  /// - Con varios estados (en tiempo / crítico) se aplica OR entre ellos.
  /// - RUTINAS es independiente: deja solo las misiones que se repiten y se
  ///   combina con el resto (p. ej. RUTINAS + CRÍTICO = rutinas vencidas).
  /// - COMPLETADAS no se resuelve aquí: la lista de completadas se obtiene con
  ///   [entradasCompletadas].
  /// - Las tareas cuyo id esté en [idsFijados] (recién marcadas o desmarcadas)
  ///   superan siempre el filtro de estado para no desaparecer de la vista
  ///   mientras el usuario interactúa con ellas.
  static List<Task> filtrar(
    List<Task> tareas, {
    Set<TaskStatusFilter> estados = const <TaskStatusFilter>{},
    String? categoria,
    Set<int> idsFijados = const <int>{},
    DateTime? ahora,
  }) {
    final String? categoriaLimpia = categoria?.toUpperCase().trim();
    final bool hayCategoria =
        categoriaLimpia != null && categoriaLimpia.isNotEmpty;

    final bool soloRutinas = estados.contains(TaskStatusFilter.rutinas);
    final Set<TaskStatusFilter> estadosReales = estados
        .where(
          (TaskStatusFilter e) =>
              e != TaskStatusFilter.rutinas &&
              e != TaskStatusFilter.completadas,
        )
        .toSet();

    return tareas.where((Task tarea) {
      final int? id = tarea.id;
      final bool fijada = id != null && idsFijados.contains(id);

      final bool vencida = RoutineService.estaVencida(tarea, ahora: ahora);

      final bool cumpleEstado = fijada ||
          estadosReales.isEmpty ||
          estadosReales.any(
            (TaskStatusFilter estado) => switch (estado) {
              TaskStatusFilter.critico => vencida,
              TaskStatusFilter.enTiempo => !vencida && !tarea.completada,
              TaskStatusFilter.rutinas => true,
              TaskStatusFilter.completadas => true,
            },
          );

      final bool cumpleRutina = !soloRutinas || tarea.esRutina;

      final bool cumpleCategoria = !hayCategoria ||
          tarea.categoriaId.toUpperCase().trim() == categoriaLimpia;

      return cumpleEstado && cumpleRutina && cumpleCategoria;
    }).toList();
  }

  /// Filas de la pestaña COMPLETADAS, de la más reciente a la más antigua:
  /// una por cada misión normal finalizada y una por cada ejecución marcada en
  /// el historial de una rutina. Con [soloRutinas] se omiten las misiones
  /// normales.
  static List<CompletedEntry> entradasCompletadas(
    List<Task> tareas, {
    String? categoria,
    bool soloRutinas = false,
  }) {
    final String? categoriaLimpia = categoria?.toUpperCase().trim();
    final bool hayCategoria =
        categoriaLimpia != null && categoriaLimpia.isNotEmpty;

    final List<CompletedEntry> entradas = <CompletedEntry>[];
    for (final Task tarea in tareas) {
      if (hayCategoria &&
          tarea.categoriaId.toUpperCase().trim() != categoriaLimpia) {
        continue;
      }
      if (tarea.esRutina) {
        for (final String fecha in RoutineService.historial(tarea)) {
          entradas.add(CompletedEntry(tarea: tarea, fecha: fecha));
        }
      } else if (!soloRutinas && tarea.completada) {
        entradas.add(CompletedEntry(tarea: tarea));
      }
    }

    entradas.sort((CompletedEntry a, CompletedEntry b) {
      final int porFecha = b.claveOrden.compareTo(a.claveOrden);
      if (porFecha != 0) return porFecha;
      return (b.tarea.id ?? 0).compareTo(a.tarea.id ?? 0);
    });
    return entradas;
  }
}