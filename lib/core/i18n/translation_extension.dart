// lib/core/i18n/translation_extension.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recordapp/features/settings/domain/services/translator.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';

/// Traduce con respaldo: si el diccionario aún no cargó o falta la clave,
/// devuelve [fallback].
String translate(Translator? translator, String key, String fallback) {
  if (translator == null) return fallback;
  return translator.t(key, fallback: fallback);
}

extension TranslationRef on WidgetRef {
  /// Para usar dentro de `build` (se suscribe a cambios de idioma).
  String tr(String key, String fallback) {
    return translate(watch(translatorProvider).value, key, fallback);
  }

  /// Para usar dentro de callbacks (no se suscribe).
  String trOnce(String key, String fallback) {
    return translate(read(translatorProvider).value, key, fallback);
  }

  /// Nombre visible de una categoría (`TRABAJO` → `WORK`, `TRABALHO`…).
  ///
  /// El identificador (`TRABAJO`) es lo que se guarda en la base de datos y lo
  /// que usan los filtros: NO cambia con el idioma. Solo se traduce lo que se
  /// muestra. Si no hay traducción, se muestra el propio identificador.
  /// Para usar dentro de `build` (se suscribe a cambios de idioma).
  String trCategoria(String id) {
    final String limpio = id.trim();
    return tr('categories.${limpio.toLowerCase()}', limpio);
  }
}