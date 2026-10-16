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
}
