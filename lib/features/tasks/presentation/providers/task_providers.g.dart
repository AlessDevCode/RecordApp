// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taskLocalDatasource)
final taskLocalDatasourceProvider = TaskLocalDatasourceProvider._();

final class TaskLocalDatasourceProvider
    extends
        $FunctionalProvider<
          TaskLocalDatasource,
          TaskLocalDatasource,
          TaskLocalDatasource
        >
    with $Provider<TaskLocalDatasource> {
  TaskLocalDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskLocalDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskLocalDatasourceHash();

  @$internal
  @override
  $ProviderElement<TaskLocalDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TaskLocalDatasource create(Ref ref) {
    return taskLocalDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskLocalDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskLocalDatasource>(value),
    );
  }
}

String _$taskLocalDatasourceHash() =>
    r'f3a6f15a7faa2a46830d662dfffbe738487169b2';

@ProviderFor(taskRepository)
final taskRepositoryProvider = TaskRepositoryProvider._();

final class TaskRepositoryProvider
    extends $FunctionalProvider<TaskRepository, TaskRepository, TaskRepository>
    with $Provider<TaskRepository> {
  TaskRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaskRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskRepository create(Ref ref) {
    return taskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskRepository>(value),
    );
  }
}

String _$taskRepositoryHash() => r'cb3bbfe0132f84f1a0f99daeccff2dfdc6c9b2b3';

/// IDs de misiones cuyo estado de completado acaba de cambiar. Siguen visibles
/// aunque el filtro de estado activo las excluiría, hasta que el usuario cambie
/// los filtros o refresque la lista.

@ProviderFor(TareasFijadas)
final tareasFijadasProvider = TareasFijadasProvider._();

/// IDs de misiones cuyo estado de completado acaba de cambiar. Siguen visibles
/// aunque el filtro de estado activo las excluiría, hasta que el usuario cambie
/// los filtros o refresque la lista.
final class TareasFijadasProvider
    extends $NotifierProvider<TareasFijadas, Set<int>> {
  /// IDs de misiones cuyo estado de completado acaba de cambiar. Siguen visibles
  /// aunque el filtro de estado activo las excluiría, hasta que el usuario cambie
  /// los filtros o refresque la lista.
  TareasFijadasProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tareasFijadasProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tareasFijadasHash();

  @$internal
  @override
  TareasFijadas create() => TareasFijadas();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$tareasFijadasHash() => r'c88f62f1d5013ff674152ad5043688ab4688d2ba';

/// IDs de misiones cuyo estado de completado acaba de cambiar. Siguen visibles
/// aunque el filtro de estado activo las excluiría, hasta que el usuario cambie
/// los filtros o refresque la lista.

abstract class _$TareasFijadas extends $Notifier<Set<int>> {
  Set<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<int>, Set<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<int>, Set<int>>,
              Set<int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TaskList)
final taskListProvider = TaskListProvider._();

final class TaskListProvider
    extends $AsyncNotifierProvider<TaskList, List<Task>> {
  TaskListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskListHash();

  @$internal
  @override
  TaskList create() => TaskList();
}

String _$taskListHash() => r'ab06cda6d4400499345cfe492af4b653f03c981a';

abstract class _$TaskList extends $AsyncNotifier<List<Task>> {
  FutureOr<List<Task>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Task>>, List<Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Task>>, List<Task>>,
              AsyncValue<List<Task>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TaskFilter)
final taskFilterProvider = TaskFilterProvider._();

final class TaskFilterProvider
    extends $NotifierProvider<TaskFilter, TaskFilterState> {
  TaskFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskFilterHash();

  @$internal
  @override
  TaskFilter create() => TaskFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskFilterState>(value),
    );
  }
}

String _$taskFilterHash() => r'c329505be8c501e4a1cce6d15d9ca9dd9dc68aa8';

abstract class _$TaskFilter extends $Notifier<TaskFilterState> {
  TaskFilterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TaskFilterState, TaskFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TaskFilterState, TaskFilterState>,
              TaskFilterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredTasks)
final filteredTasksProvider = FilteredTasksProvider._();

final class FilteredTasksProvider
    extends $FunctionalProvider<List<Task>, List<Task>, List<Task>>
    with $Provider<List<Task>> {
  FilteredTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredTasksHash();

  @$internal
  @override
  $ProviderElement<List<Task>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Task> create(Ref ref) {
    return filteredTasks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Task> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Task>>(value),
    );
  }
}

String _$filteredTasksHash() => r'4330699feb0c01f042ea815aee29476d1694cd20';

/// Sugerencia de categoría en tiempo real a partir del título.

@ProviderFor(autodetectedCategory)
final autodetectedCategoryProvider = AutodetectedCategoryFamily._();

/// Sugerencia de categoría en tiempo real a partir del título.

final class AutodetectedCategoryProvider
    extends $FunctionalProvider<TaskCategory, TaskCategory, TaskCategory>
    with $Provider<TaskCategory> {
  /// Sugerencia de categoría en tiempo real a partir del título.
  AutodetectedCategoryProvider._({
    required AutodetectedCategoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'autodetectedCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$autodetectedCategoryHash();

  @override
  String toString() {
    return r'autodetectedCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TaskCategory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskCategory create(Ref ref) {
    final argument = this.argument as String;
    return autodetectedCategory(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskCategory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskCategory>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AutodetectedCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$autodetectedCategoryHash() =>
    r'bef91fac4246b8c33c75feb795e5bb8106b35b4f';

/// Sugerencia de categoría en tiempo real a partir del título.

final class AutodetectedCategoryFamily extends $Family
    with $FunctionalFamilyOverride<TaskCategory, String> {
  AutodetectedCategoryFamily._()
    : super(
        retry: null,
        name: r'autodetectedCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sugerencia de categoría en tiempo real a partir del título.

  AutodetectedCategoryProvider call(String titulo) =>
      AutodetectedCategoryProvider._(argument: titulo, from: this);

  @override
  String toString() => r'autodetectedCategoryProvider';
}
