// lib/features/settings/data/datasources/settings_local_datasource.dart
import 'dart:convert';

import 'package:recordapp/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Persistencia clave/valor de la configuración. Cada valor se guarda
/// codificado en JSON para conservar su tipo (bool, String, etc.).
class SettingsLocalDatasource {
  SettingsLocalDatasource(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<Map<String, Object?>> readAll() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, Object?>> rows =
        await db.query(DbTables.configuracion);

    final Map<String, Object?> resultado = <String, Object?>{};
    for (final Map<String, Object?> row in rows) {
      final Object? clave = row['clave'];
      final Object? valor = row['valor'];
      if (clave is! String || valor is! String) continue;
      try {
        resultado[clave] = jsonDecode(valor);
      } on FormatException {
        continue;
      }
    }
    return resultado;
  }

  Future<void> writeAll(Map<String, Object?> values) async {
    final Database db = await _dbHelper.database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      values.forEach((String clave, Object? valor) {
        batch.insert(
          DbTables.configuracion,
          <String, Object?>{'clave': clave, 'valor': jsonEncode(valor)},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      await batch.commit(noResult: true);
    });
  }
}
