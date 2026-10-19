// lib/features/tasks/presentation/providers/task_providers.dart
import 'dart:async';

import 'package:recordapp/core/database/database_provider.dart';
import 'package:recordapp/features/alarms/domain/services/reminder_planner.dart';
import 'package:recordapp/features/alarms/presentation/providers/notification_providers.dart';
import 'package:recordapp/features/alarms/presentation/providers/persistent_status_provider.dart';
import 'package:recordapp/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:recordapp/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:recordapp/features/tasks/domain/models/alarm_type.dart';
import 'package:recordapp/features/tasks/domain/models/repeat_type.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/models/task_category.dart';
import 'package:recordapp/features/tasks/domain/models/task_filter_state.dart';
import 'package:recordapp/features/tasks/domain/models/task_status_filter.dart';
import 'package:recordapp/features/tasks/domain/repositories/task_repository.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';
import 'package:recordapp/features/tasks/domain/services/smart_tagger.dart';
import 'package:recordapp/features/tasks/domain/services/task_filter_service.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';
import 'package:recordapp/features/tasks/presentation/providers/clock_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_providers.g.dart';

/// Valor del selector de categoría que delega en el detector automático.
const String kCategoriaAutomatica = 'AUTOMÁTICO';

@Riverpod(keepAlive: true)
TaskLocalDatasource taskLocalDatasource(Ref ref) {
  return TaskLocalDatasource(ref.watch(databaseHelperProvider));
}

@Riverpod(keepAlive: true)
TaskRepository taskRepository(Ref ref) {
  return TaskRepositoryImpl(ref.watch(taskLocalDatasourceProvider));
}

/// IDs de misiones cuyo estado de completado acaba de cambiar. Siguen visibles
/// aunque el filtro de estado activo las excluiría, hasta que el usuario cambie
/// los filtros o refresque la lista.
@Riverpod(keepAlive: true)
class TareasFijadas extends _$TareasFijadas {
  @override
  Set<int> build() => const <int>{};

  void fijar(int id) {
    state = <int>{...state, id};
  }

  void limpiar() {
    if (state.isNotEmpty) {
      state = const <int>{};
    }
  }
}

@Riverpod(keepAlive: true)
class TaskList extends _$TaskList {
  @override
  Future<List<Task>> build() {
    return ref.watch(taskRepositoryProvider).getAllTasks();
  }

  /// Recarga las tareas desde SQLite y actualiza el estado.
  Future<List<Task>> cargarTareas() async {
    ref.read(tareasFijadasProvider.notifier).limpiar();
    state = await AsyncValue.guard(
      () => ref.read(taskRepositoryProvider).getAllTasks(),
    );
    return state.value ?? const <Task>[];
  }

  /// Aplica las reglas de negocio del formulario y persiste la tarea
  /// (alta, o edición si se pasa [existente]) y reprograma sus notificaciones.
  /// Devuelve false si el título está vacío.
  Future<bool> guardarTarea({
    required String titulo,
    required String descripcion,
    required String categoriaSeleccionada,
    required String categoriaActualAutomatica,
    required String fecha,
    required String hora,
    required AlarmType tipoAlarma,
    String sonido = '',
    String sonidoUri = '',
    String sonidoNombre = '',
    int duracionSeg = 0,
    RepeatType repeatType = RepeatType.none,
    Set<int> repeatDays = const <int>{},
    List<String> customDates = const <String>[],
    Map<String, String> repeatTimes = const <String, String>{},
    int repeatCount = 0,
    int intervalMinutes = 0,
    Task? existente,
  }) async {
    if (titulo.trim().isEmpty) return false;

    final String categoriaFinal = categoriaSeleccionada == kCategoriaAutomatica
        ? categoriaActualAutomatica
        : categoriaSeleccionada;

    final String fechaFinal;
    final String horaFinal;
    final AlarmType alarmaFinal;

    if (categoriaFinal == 'NOTAS') {
      fechaFinal = '';
      horaFinal = '';
      alarmaFinal = AlarmType.silencioso;
    } else {
      fechaFinal = fecha.trim();
      horaFinal = hora.trim();
      alarmaFinal =
          categoriaFinal == 'ALARMA' ? AlarmType.sonido : tipoAlarma;
    }

    // El sonido (archivo de assets o audio propio) y su duración solo se
    // conservan en modo "sonido"; un audio propio tiene prioridad.
    final bool conSonido = alarmaFinal == AlarmType.sonido;
    final String sonidoUriFinal = conSonido ? sonidoUri.trim() : '';
    final String sonidoNombreFinal =
        sonidoUriFinal.isEmpty ? '' : sonidoNombre.trim();
    final String sonidoFinal =
        conSonido && sonidoUriFinal.isEmpty ? sonido.trim() : '';
    final int duracionFinal = conSonido && duracionSeg > 0 ? duracionSeg : 0;

    // Repetición automática de la alarma: solo con sonido o vibración. Si no
    // hay repeticiones, tampoco se guarda intervalo.
    final int reintentosFinal =
        alarmaFinal != AlarmType.silencioso && repeatCount > 0
            ? repeatCount.clamp(1, ReminderPlanner.maxRepeticiones).toInt()
            : 0;
    final int intervaloFinal = reintentosFinal == 0
        ? 0
        : (intervalMinutes > 0 ? intervalMinutes.clamp(1, 120).toInt() : 5);

    // Rutinas: no aplican a las notas. Una rutina no tiene fecha límite única
    // (cada ocurrencia usa la hora límite en sus días o fechas).
    final RepeatType repeatFinal =
        categoriaFinal == 'NOTAS' ? RepeatType.none : repeatType;
    final Set<int> diasFinal = repeatFinal == RepeatType.weekly
        ? <int>{...repeatDays.where((int d) => d >= 1 && d <= 7)}
        : const <int>{};
    final List<String> fechasFinal = repeatFinal == RepeatType.customDates
        ? (customDates.toSet().toList()..sort())
        : const <String>[];

    // Bloques de horario: solo valen para días o fechas elegidos y con una
    // hora válida; el resto usa la hora principal.
    final Map<String, String> horariosFinal = <String, String>{
      for (final MapEntry<String, String> e in repeatTimes.entries)
        if (RoutineService.horaValida(e.value) &&
            (repeatFinal == RepeatType.weekly
                ? diasFinal.contains(int.tryParse(e.key))
                : repeatFinal == RepeatType.customDates &&
                    fechasFinal.contains(e.key)))
          e.key: e.value.trim(),
    };

    // La fecha de creación es el ancla de los recordatorios de 5 h: se
    // conserva al editar.
    final String creacion = (existente?.fechaCreacion.isNotEmpty ?? false)
        ? existente!.fechaCreacion
        : DateTime.now().toIso8601String();

    final Task tarea = Task(
      id: existente?.id,
      titulo: titulo.trim(),
      descripcion: descripcion.trim(),
      fechaLimite: repeatFinal == RepeatType.none ? fechaFinal : '',
      horaLimite: horaFinal,
      tipoAlarma: alarmaFinal,
      sonido: sonidoFinal,
      sonidoUri: sonidoUriFinal,
      sonidoNombre: sonidoNombreFinal,
      duracionSeg: duracionFinal,
      fechaCreacion: creacion,
      categoriaId: categoriaFinal,
      // Una rutina nunca nace archivada: al editarla se reactiva.
      completada: repeatFinal == RepeatType.none
          ? (existente?.completada ?? false)
          : false,
      repeatType: repeatFinal,
      repeatDays: diasFinal,
      customDates: fechasFinal,
      repeatTimes: horariosFinal,
      repeatCount: reintentosFinal,
      intervalMinutes: intervaloFinal,
      // El historial de ejecuciones se conserva al editar la rutina.
      doneDates: repeatFinal == RepeatType.none
          ? const <String>{}
          : (existente?.doneDates ?? const <String>{}),
    );

    final TaskRepository repo = ref.read(taskRepositoryProvider);
    final Task guardada;
    if (existente == null) {
      final int id = await repo.addTask(tarea);
      guardada = tarea.copyWith(id: id);
    } else {
      await repo.updateTask(tarea);
      guardada = tarea;
    }

    await _reprogramar(guardada);
    await cargarTareas();
    _refrescarEstadoFijo();
    return true;
  }

  /// Actualiza una tarea existente (debe tener id).
  Future<void> actualizarTarea(Task tarea) async {
    final TaskRepository repo = ref.read(taskRepositoryProvider);
    await repo.updateTask(tarea);
    await _reprogramar(tarea);
    await cargarTareas();
    _refrescarEstadoFijo();
  }

  /// Elimina físicamente la tarea, cancela sus notificaciones y actualiza el
  /// estado en memoria.
  Future<void> eliminarTarea(int taskId) async {
    final List<Task> actuales = state.value ?? await future;
    await ref.read(taskRepositoryProvider).deleteTask(taskId);
    await ref
        .read(missionNotificationSchedulerProvider)
        .cancelarMision(taskId);
    state = AsyncData<List<Task>>(
      actuales.where((Task t) => t.id != taskId).toList(),
    );
    _refrescarEstadoFijo();
  }

  /// Marca una tarea como completada o pendiente. La tarea queda fijada en la
  /// vista (aunque el filtro activo la excluiría) hasta que cambien los filtros
  /// o se refresque la lista. Al completar se cancelan sus notificaciones; al
  /// desmarcar se reprograman.
  Future<void> cambiarEstadoCompletado(
    int taskId, {
    required bool completada,
  }) async {
    final List<Task> actuales = state.value ?? await future;

    // Rutinas: el check marca la ejecución de hoy; no archiva la misión.
    final Task? objetivo =
        actuales.where((Task t) => t.id == taskId).firstOrNull;
    if (objetivo != null && objetivo.esRutina) {
      await _marcarRutina(objetivo, actuales, hecha: completada);
      return;
    }

    await ref
        .read(taskRepositoryProvider)
        .updateTaskStatus(taskId, completada: completada);

    ref.read(tareasFijadasProvider.notifier).fijar(taskId);

    final List<Task> nuevas = actuales
        .map(
          (Task t) => t.id == taskId ? t.copyWith(completada: completada) : t,
        )
        .toList();
    state = AsyncData<List<Task>>(nuevas);

    for (final Task t in nuevas) {
      if (t.id == taskId) {
        await _reprogramar(t);
        break;
      }
    }
    _refrescarEstadoFijo();
  }

  /// Check de una rutina (weekly / custom_dates).
  ///
  /// - Al marcar: se añade hoy al historial (`doneDates`), lo que también
  ///   limpia el estado vencido de hoy. La rutina NO pasa a culminada y se
  ///   reprograma para la siguiente ocurrencia activa (la de hoy deja de
  ///   programarse).
  /// - Al desmarcar: se quita hoy del historial y vuelve a programarse.
  /// - Excepción: en fechas especiales, si ya no queda ninguna fecha futura,
  ///   la rutina terminó y se archiva como culminada.
  Future<void> _marcarRutina(
    Task rutina,
    List<Task> actuales, {
    required bool hecha,
  }) async {
    final int? id = rutina.id;
    if (id == null) return;

    final DateTime ahora = DateTime.now();
    final String hoy = TimeFormatter.fechaDb(ahora);

    final Set<String> nuevas = <String>{...rutina.doneDates};
    if (hecha) {
      nuevas.add(hoy);
    } else {
      nuevas.remove(hoy);
    }

    Task actualizada = rutina.copyWith(
      doneDates: _recortarHistorial(nuevas),
      completada: false,
    );
    if (hecha &&
        rutina.repeatType == RepeatType.customDates &&
        RoutineService.proximaEjecucion(actualizada, ahora: ahora) == null) {
      actualizada = actualizada.copyWith(completada: true);
    }

    await _guardarRutina(actualizada, actuales);
  }

  /// "Deshacer" de la pestaña COMPLETADAS: quita [fecha] del historial de la
  /// rutina. Si la rutina estaba archivada (fechas especiales terminadas), se
  /// reactiva. La ocurrencia vuelve a programarse si todavía está por venir.
  Future<void> deshacerEjecucion(int taskId, String fecha) async {
    final List<Task> actuales = state.value ?? await future;
    final Task? rutina =
        actuales.where((Task t) => t.id == taskId).firstOrNull;
    if (rutina == null || !rutina.esRutina) return;

    final Task actualizada = rutina.copyWith(
      doneDates: <String>{...rutina.doneDates}..remove(fecha),
      completada: false,
    );
    await _guardarRutina(actualizada, actuales);
  }

  /// Conserva solo las últimas [RoutineService.maxHistorial] ejecuciones.
  Set<String> _recortarHistorial(Set<String> fechas) {
    if (fechas.length <= RoutineService.maxHistorial) return fechas;
    final List<String> ordenadas = fechas.toList()..sort();
    return ordenadas
        .sublist(ordenadas.length - RoutineService.maxHistorial)
        .toSet();
  }

  Future<void> _guardarRutina(Task rutina, List<Task> actuales) async {
    final int? id = rutina.id;
    if (id == null) return;

    await ref.read(taskRepositoryProvider).updateTask(rutina);
    ref.read(tareasFijadasProvider.notifier).fijar(id);
    state = AsyncData<List<Task>>(
      actuales.map((Task t) => t.id == id ? rutina : t).toList(),
    );
    await _reprogramar(rutina);
    _refrescarEstadoFijo();
  }

  /// Refresca de inmediato la notificación fija de estado, sin esperar al
  /// siguiente minuto del reloj ni al aviso de cambio de la lista. Se llama al
  /// terminar cada alta, edición, baja o check, cuando la lista en memoria ya
  /// está actualizada.
  void _refrescarEstadoFijo() {
    unawaited(ref.read(persistentStatusUpdaterProvider).actualizar());
  }

  Future<void> _reprogramar(Task tarea) async {
    final int? id = tarea.id;
    if (id == null) return;
    final MissionNotificationScheduler scheduler =
        ref.read(missionNotificationSchedulerProvider);
    if (tarea.completada) {
      await scheduler.cancelarMision(id);
    } else {
      await scheduler.programarMision(tarea);
    }
  }
}

@riverpod
class TaskFilter extends _$TaskFilter {
  @override
  TaskFilterState build() => const TaskFilterState();

  void alternarEstado(TaskStatusFilter estado) {
    final Set<TaskStatusFilter> nuevos = <TaskStatusFilter>{...state.estados};
    if (!nuevos.remove(estado)) {
      nuevos.add(estado);
      // COMPLETADAS (historial) no se mezcla con EN TIEMPO ni CRÍTICO.
      if (estado == TaskStatusFilter.completadas) {
        nuevos
          ..remove(TaskStatusFilter.enTiempo)
          ..remove(TaskStatusFilter.critico);
      } else if (estado == TaskStatusFilter.enTiempo ||
          estado == TaskStatusFilter.critico) {
        nuevos.remove(TaskStatusFilter.completadas);
      }
    }
    state = state.copyWith(estados: nuevos);
    ref.read(tareasFijadasProvider.notifier).limpiar();
  }

  void establecerCategoria(String? categoria) {
    final String? limpia = categoria?.trim();
    state = state.copyWith(
      categoria: (limpia == null || limpia.isEmpty) ? null : limpia,
    );
    ref.read(tareasFijadasProvider.notifier).limpiar();
  }

  void limpiar() {
    state = const TaskFilterState();
    ref.read(tareasFijadasProvider.notifier).limpiar();
  }
}

@riverpod
List<Task> filteredTasks(Ref ref) {
  final List<Task> tareas =
      ref.watch(taskListProvider).value ?? const <Task>[];
  final TaskFilterState filtro = ref.watch(taskFilterProvider);
  final Set<int> fijadas = ref.watch(tareasFijadasProvider);
  // Se recalcula cada minuto: así una rutina sale de CRÍTICO sola cuando
  // termina su ventana de 30 minutos.
  final DateTime ahora = ref.watch(clockProvider).value ?? DateTime.now();
  return TaskFilterService.filtrar(
    tareas,
    estados: filtro.estados,
    categoria: filtro.categoria,
    idsFijados: fijadas,
    ahora: ahora,
  );
}

/// Sugerencia de categoría en tiempo real a partir del título.
@riverpod
TaskCategory autodetectedCategory(Ref ref, String titulo) {
  return SmartTagger.escanearCategoria(titulo);
}