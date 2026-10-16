// lib/features/tasks/domain/models/task_filter_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:recordapp/features/tasks/domain/models/task_status_filter.dart';

part 'task_filter_state.freezed.dart';

@freezed
abstract class TaskFilterState with _$TaskFilterState {
  const factory TaskFilterState({
    @Default(<TaskStatusFilter>{}) Set<TaskStatusFilter> estados,
    String? categoria,
  }) = _TaskFilterState;
}
