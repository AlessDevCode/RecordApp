// lib/core/database/database_helper.dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

abstract final class DbTables {
  static const String tareas = 'tareas';
  static const String configuracion = 'configuracion';
}

abstract final class DbSchema {
  static const String createTareas = '''
    CREATE TABLE ${DbTables.tareas} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL,
      descripcion TEXT NOT NULL DEFAULT '',
      fecha_limite TEXT NOT NULL DEFAULT '',
      hora_limite TEXT NOT NULL DEFAULT '',
      tipo_alarma TEXT NOT NULL DEFAULT 'SONIDO',
      sonido TEXT NOT NULL DEFAULT '',
      sonido_uri TEXT NOT NULL DEFAULT '',
      sonido_nombre TEXT NOT NULL DEFAULT '',
      duracion_seg INTEGER NOT NULL DEFAULT 0,
      repeat_type TEXT NOT NULL DEFAULT 'none',
      repeat_days TEXT NOT NULL DEFAULT '',
      custom_dates TEXT NOT NULL DEFAULT '',
      last_done TEXT NOT NULL DEFAULT '',
      repeat_times TEXT NOT NULL DEFAULT '',
      done_dates TEXT NOT NULL DEFAULT '',
      repeat_count INTEGER NOT NULL DEFAULT 0,
      interval_minutes INTEGER NOT NULL DEFAULT 0,
      fecha_creacion TEXT NOT NULL DEFAULT '',
      categoria_id TEXT NOT NULL DEFAULT 'NOTAS',
      completada INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String createConfiguracion = '''
    CREATE TABLE ${DbTables.configuracion} (
      clave TEXT PRIMARY KEY,
      valor TEXT NOT NULL
    )
  ''';

  static const String indexTareasFecha = '''
    CREATE INDEX idx_tareas_fecha_hora
    ON ${DbTables.tareas} (fecha_limite, hora_limite)
  ''';

  static const String indexTareasCategoria = '''
    CREATE INDEX idx_tareas_categoria
    ON ${DbTables.tareas} (categoria_id)
  ''';

  static const List<String> createScripts = <String>[
    createTareas,
    createConfiguracion,
    indexTareasFecha,
    indexTareasCategoria,
  ];
}

class DatabaseHelper {
  DatabaseHelper({
    this.databaseName = 'db_recordapp.db',
    this.databasePathOverride,
  });

  /// v1: esquema inicial.
  /// v2: columnas `sonido` (archivo de audio elegido) y `fecha_creacion`
  ///     (ancla de los recordatorios periódicos).
  /// v3: audio propio (`sonido_uri`, `sonido_nombre`) y duración del sonido
  ///     (`duracion_seg`, 0 = la del propio audio).
  /// v4: rutinas — `repeat_type` ('none' | 'weekly' | 'custom_dates'),
  ///     `repeat_days` ("1,3,5", 1 = lunes), `custom_dates` (fechas ISO
  ///     separadas por comas) y `last_done` (fecha de la última ejecución
  ///     marcada como hecha).
  /// v5: horarios por día/fecha (`repeat_times`, JSON `{"1":"08:00"}`) e
  ///     historial de ejecuciones (`done_dates`, fechas ISO separadas por
  ///     comas). `done_dates` sustituye a `last_done`, que se conserva en la
  ///     tabla sin uso (SQLite no permite borrar columnas con facilidad).
  /// v6: repetición automática de la alarma — `repeat_count` (veces que se
  ///     repite tras la primera, 0 = desactivada) e `interval_minutes`.
  static const int _version = 6;

  final String databaseName;

  /// Permite inyectar una ruta (por ejemplo `inMemoryDatabasePath` en tests).
  final String? databasePathOverride;

  Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _open();

  Future<Database> _open() async {
    final String path =
        databasePathOverride ?? p.join(await getDatabasesPath(), databaseName);

    return openDatabase(
      path,
      version: _version,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        final Batch batch = db.batch();
        for (final String script in DbSchema.createScripts) {
          batch.execute(script);
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          final Batch batch = db.batch();
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN sonido TEXT NOT NULL DEFAULT ''",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN fecha_creacion TEXT NOT NULL DEFAULT ''",
          );
          // Las misiones existentes toman el momento de la migración como
          // "creación"; así los recordatorios de 5 h quedan anclados a una
          // fecha estable y no se desplazan en cada arranque.
          batch.update(
            DbTables.tareas,
            <String, Object?>{
              'fecha_creacion': DateTime.now().toIso8601String(),
            },
            where: "fecha_creacion = ''",
          );
          await batch.commit(noResult: true);
        }
        if (oldVersion < 3) {
          final Batch batch = db.batch();
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN sonido_uri TEXT NOT NULL DEFAULT ''",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN sonido_nombre TEXT NOT NULL DEFAULT ''",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN duracion_seg INTEGER NOT NULL DEFAULT 0",
          );
          await batch.commit(noResult: true);
        }
        if (oldVersion < 4) {
          final Batch batch = db.batch();
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN repeat_type TEXT NOT NULL DEFAULT 'none'",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN repeat_days TEXT NOT NULL DEFAULT ''",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN custom_dates TEXT NOT NULL DEFAULT ''",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN last_done TEXT NOT NULL DEFAULT ''",
          );
          await batch.commit(noResult: true);
        }
        if (oldVersion < 5) {
          final Batch batch = db.batch();
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN repeat_times TEXT NOT NULL DEFAULT ''",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN done_dates TEXT NOT NULL DEFAULT ''",
          );
          // La última ejecución de la v4 pasa a ser la primera del historial.
          batch.execute(
            "UPDATE ${DbTables.tareas} SET done_dates = last_done "
            "WHERE last_done != ''",
          );
          await batch.commit(noResult: true);
        }
        if (oldVersion < 6) {
          final Batch batch = db.batch();
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN repeat_count INTEGER NOT NULL DEFAULT 0",
          );
          batch.execute(
            "ALTER TABLE ${DbTables.tareas} "
            "ADD COLUMN interval_minutes INTEGER NOT NULL DEFAULT 0",
          );
          await batch.commit(noResult: true);
        }
      },
    );
  }

  Future<void> close() async {
    final Future<Database>? future = _dbFuture;
    _dbFuture = null;
    if (future != null) {
      final Database db = await future;
      await db.close();
    }
  }
}