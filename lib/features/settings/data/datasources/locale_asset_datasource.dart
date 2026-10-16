// lib/features/settings/data/datasources/locale_asset_datasource.dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class LocaleAssetDatasource {
  const LocaleAssetDatasource();

  /// Carga `assets/locales/<language>.json`; si falla, usa `es.json`.
  /// Si ninguno existe devuelve un diccionario vacío.
  Future<Map<String, dynamic>> load(String language) async {
    for (final String codigo in <String>[language, 'es']) {
      try {
        final String raw =
            await rootBundle.loadString('assets/locales/$codigo.json');
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        continue;
      }
    }
    return <String, dynamic>{};
  }
}
