// lib/features/tasks/data/repositories/task_repository_impl.dart
import 'package:recordapp/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._datasource);

  final TaskLocalDatasource _datasource;

  @override
  Future<List<Task>> getAllTasks() => _datasource.getAllTasks();

  @override
  Future<Task?> getTaskById(int id) => _datasource.getTaskById(id);

  @override
  Future<int> addTask(Task task) => _datasource.insertTask(task);

  @override
  Future<void> updateTask(Task task) => _datasource.updateTask(task);

  @override
  Future<void> deleteTask(int id) => _datasource.deleteTask(id);

  @override
  Future<void> updateTaskStatus(int id, {required bool completada}) =>
      _datasource.updateTaskStatus(id, completada: completada);
}
