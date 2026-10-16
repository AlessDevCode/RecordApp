// lib/features/tasks/domain/services/smart_tagger.dart
import 'package:recordapp/features/tasks/domain/models/task_category.dart';

abstract final class SmartTagger {
  static const TaskCategory notas = TaskCategory(nombre: 'NOTAS', emoji: '📝');
  static const TaskCategory alarma = TaskCategory(nombre: 'ALARMA', emoji: '⏰');
  static const TaskCategory trabajo =
      TaskCategory(nombre: 'TRABAJO', emoji: '💼');
  static const TaskCategory estudio =
      TaskCategory(nombre: 'ESTUDIO', emoji: '📚');
  static const TaskCategory salud = TaskCategory(nombre: 'SALUD', emoji: '❤️');
  static const TaskCategory compras =
      TaskCategory(nombre: 'COMPRAS', emoji: '🛒');
  static const TaskCategory finanzas =
      TaskCategory(nombre: 'FINANZAS', emoji: '💰');
  static const TaskCategory hogar = TaskCategory(nombre: 'HOGAR', emoji: '🏠');
  static const TaskCategory social =
      TaskCategory(nombre: 'SOCIAL', emoji: '🎉');

  /// Orden de prioridad ante empates.
  static const List<TaskCategory> categorias = <TaskCategory>[
    alarma,
    trabajo,
    estudio,
    salud,
    compras,
    finanzas,
    hogar,
    social,
    notas,
  ];

  static const Map<String, List<String>> _palabrasClave =
      <String, List<String>>{
    'ALARMA': <String>[
      'alarma',
      'despert',
      'desperta',
      'alerta',
      'avisa',
      'recuerd',
      'recordatorio',
    ],
    'TRABAJO': <String>[
      'reunion',
      'trabajo',
      'oficina',
      'cliente',
      'proyecto',
      'informe',
      'reporte',
      'entrega',
      'deadline',
      'jefe',
      'presentacion',
      'meeting',
      'correo',
      'email',
      'sprint',
      'deploy',
    ],
    'ESTUDIO': <String>[
      'estudi',
      'examen',
      'tarea',
      'clase',
      'universidad',
      'colegio',
      'curso',
      'leer',
      'lectura',
      'tesis',
      'exposicion',
      'practica',
      'repasar',
      'TIF'
    ],
    'SALUD': <String>[
      'medic',
      'doctor',
      'dentista',
      'cita',
      'pastilla',
      'gimnasio',
      'ejercicio',
      'entrenar',
      'hospital',
      'terapia',
      'salud',
      'vacuna',
      'analisis',
    ],
    'COMPRAS': <String>[
      'compra',
      'comprar',
      'supermercado',
      'mercado',
      'tienda',
      'pedido',
      'regalo',
      'farmacia',
      'ordenar',
    ],
    'FINANZAS': <String>[
      'pagar',
      'pago',
      'factura',
      'banco',
      'deuda',
      'cuota',
      'alquiler',
      'renta',
      'impuesto',
      'prestamo',
      'transferencia',
      'ahorro',
      'tarjeta',
    ],
    'HOGAR': <String>[
      'limpiar',
      'limpieza',
      'cocinar',
      'lavar',
      'casa',
      'cocina',
      'jardin',
      'arreglar',
      'reparar',
      'mudanza',
      'basura',
      'ropa',
    ],
    'SOCIAL': <String>[
      'cumple',
      'fiesta',
      'amigo',
      'amiga',
      'familia',
      'cena',
      'almuerzo',
      'salida',
      'viaje',
      'boda',
      'aniversario',
      'visita',
    ],
  };

  static String _normalizar(String texto) {
    const String origen = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const String destino = 'aaaaaeeeeiiiiooooouuuunc';
    final StringBuffer buffer = StringBuffer();
    for (final int rune in texto.toLowerCase().runes) {
      final String caracter = String.fromCharCode(rune);
      final int indice = origen.indexOf(caracter);
      buffer.write(indice >= 0 ? destino[indice] : caracter);
    }
    return buffer.toString();
  }

  /// Escanea el título y devuelve la categoría con más coincidencias.
  /// Sin coincidencias (o título vacío) devuelve NOTAS.
  static TaskCategory escanearCategoria(String titulo) {
    if (titulo.trim().isEmpty) return notas;

    final List<String> tokens = _normalizar(titulo)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((String t) => t.isNotEmpty)
        .toList();

    TaskCategory mejor = notas;
    int mejorPuntaje = 0;

    for (final TaskCategory categoria in categorias) {
      final List<String>? claves = _palabrasClave[categoria.nombre];
      if (claves == null) continue;

      int puntaje = 0;
      for (final String token in tokens) {
        for (final String clave in claves) {
          if (token.startsWith(clave)) {
            puntaje++;
            break;
          }
        }
      }

      if (puntaje > mejorPuntaje) {
        mejorPuntaje = puntaje;
        mejor = categoria;
      }
    }

    return mejor;
  }
}
