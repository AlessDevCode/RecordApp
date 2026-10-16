// lib/features/tasks/data/datasources/task_local_datasource.dart
import 'package:recordapp/core/database/database_helper.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:sqflite/sqflite.dart';

class TaskLocalDatasource {
  TaskLocalDatasource(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<List<Task>> getAllTasks() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.tareas,
      orderBy: "completada ASC, (fecha_limite = '') ASC, "
          'fecha_limite ASC, hora_limite ASC, id DESC',
    );
    return rows.map(Task.fromJson).toList();
  }

  Future<Task?> getTaskById(int id) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.tareas,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Task.fromJson(rows.first);
  }

  Future<int> insertTask(Task task) async {
    final Database db = await _dbHelper.database;
    final Map<String, Object?> values =
        Map<String, Object?>.from(task.toJson())..remove('id');
    return db.insert(
      DbTables.tareas,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateTask(Task task) async {
    final int? id = task.id;
    if (id == null) {
      throw ArgumentError.value(task, 'task', 'La tarea no tiene id.');
    }
    final Database db = await _dbHelper.database;
    final Map<String, Object?> values =
        Map<String, Object?>.from(task.toJson())..remove('id');
    await db.update(
      DbTables.tareas,
      values,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteTask(int id) async {
    final Database db = await _dbHelper.database;
    await db.delete(
      DbTables.tareas,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateTaskStatus(int id, {required bool completada}) async {
    final Database db = await _dbHelper.database;
    await db.update(
      DbTables.tareas,
      <String, Object?>{'completada': completada ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
