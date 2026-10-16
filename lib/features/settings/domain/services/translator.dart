// lib/features/settings/domain/services/translator.dart

/// Traductor basado en un diccionario JSON anidado. Navega por claves con
/// puntos (ej: `settings.title`).
class Translator {
  const Translator(this._dictionary);

  final Map<String, dynamic> _dictionary;

  String t(String clave, {String fallback = ''}) {
    dynamic nodo = _dictionary;
    for (final String parte in clave.split('.')) {
      if (nodo is Map<String, dynamic> && nodo.containsKey(parte)) {
        nodo = nodo[parte];
      } else {
        return fallback.isNotEmpty ? fallback : clave;
      }
    }
    if (nodo == null || nodo is Map || nodo is List) {
      return fallback.isNotEmpty ? fallback : clave;
    }
    return nodo.toString();
  }
}
