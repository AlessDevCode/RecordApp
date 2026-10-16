// lib/features/tasks/domain/models/task_category.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_category.freezed.dart';
part 'task_category.g.dart';

@freezed
abstract class TaskCategory with _$TaskCategory {
  const factory TaskCategory({
    required String nombre,
    required String emoji,
  }) = _TaskCategory;

  factory TaskCategory.fromJson(Map<String, Object?> json) =>
      _$TaskCategoryFromJson(json);
}
