// test/locales_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recordapp/features/settings/domain/services/translator.dart';
import 'package:recordapp/features/tasks/domain/models/task_category.dart';
import 'package:recordapp/features/tasks/domain/services/smart_tagger.dart';

/// `{"a": {"b": "x"}}` -> `{"a.b": "x"}`.
Map<String, String> aplanar(Map<String, dynamic> nodo, [String prefijo = '']) {
  final Map<String, String> salida = <String, String>{};
  nodo.forEach((String clave, dynamic valor) {
    final String completa = prefijo.isEmpty ? clave : '$prefijo.$clave';
    if (valor is Map<String, dynamic>) {
      salida.addAll(aplanar(valor, completa));
    } else {
      salida[completa] = '$valor';
    }
  });
  return salida;
}

Map<String, dynamic> cargar(String codigo) {
  final String texto = File('assets/locales/$codigo.json').readAsStringSync();
  return jsonDecode(texto) as Map<String, dynamic>;
}

void main() {
  const List<String> idiomas = <String>['es', 'en', 'pt'];
  final RegExp marcador = RegExp(r'\{[a-z]+\}');

  final Map<String, Map<String, String>> planos = <String, Map<String, String>>{
    for (final String i in idiomas) i: aplanar(cargar(i)),
  };

  group('Archivos de idioma', () {
    test('los tres tienen exactamente las mismas claves', () {
      final Set<String> base = planos['es']!.keys.toSet();
      for (final String i in idiomas) {
        expect(planos[i]!.keys.toSet(), base, reason: 'claves de $i');
      }
    });

    test('ninguna traducción está vacía', () {
      for (final String i in idiomas) {
        planos[i]!.forEach((String clave, String texto) {
          expect(texto.trim(), isNotEmpty, reason: '$i / $clave');
        });
      }
    });

    test('conservan los mismos marcadores ({n}, {time}, {title}…)', () {
      planos['es']!.forEach((String clave, String texto) {
        final List<String> esperados =
            marcador.allMatches(texto).map((RegExpMatch m) => m[0]!).toList()
              ..sort();
        for (final String i in <String>['en', 'pt']) {
          final List<String> obtenidos = marcador
              .allMatches(planos[i]![clave]!)
              .map((RegExpMatch m) => m[0]!)
              .toList()
            ..sort();
          expect(obtenidos, esperados, reason: '$i / $clave');
        }
      });
    });

    test('cada categoría tiene su nombre traducido en los tres idiomas', () {
      for (final TaskCategory c in SmartTagger.categorias) {
        for (final String i in idiomas) {
          expect(
            planos[i]!['categories.${c.nombre.toLowerCase()}'],
            isNotNull,
            reason: '$i / categories.${c.nombre.toLowerCase()}',
          );
        }
      }
    });

    test('el texto de la categoría ALARMA forzada usa el marcador {category}', () {
      for (final String i in idiomas) {
        expect(planos[i]!['editor.alarm_forced'], contains('{category}'), reason: i);
      }
    });

    test('las listas de días tienen 7 elementos', () {
      for (final String i in idiomas) {
        for (final String clave in <String>[
          'editor.weekdays_short',
          'editor.weekdays_medium',
        ]) {
          expect(planos[i]![clave]!.split(',').length, 7, reason: '$i / $clave');
        }
      }
    });
  });

  test('Translator resuelve claves anidadas en portugués', () {
    final Translator t = Translator(cargar('pt'));
    expect(t.t('home.title'), 'MISSÕES');
    expect(t.t('editor.frequency_weekly'), 'Semanal');
    expect(t.t('no.existe', fallback: 'respaldo'), 'respaldo');
  });
}