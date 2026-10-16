// lib/features/tasks/domain/repositories/task_repository.dart
import 'package:recordapp/features/tasks/domain/models/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getAllTasks();

  Future<Task?> getTaskById(int id);

  /// Inserta la tarea y devuelve el id generado.
  Future<int> addTask(Task task);

  Future<void> updateTask(Task task);

  Future<void> deleteTask(int id);

  Future<void> updateTaskStatus(int id, {required bool completada});
}
