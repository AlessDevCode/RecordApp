// lib/features/tasks/domain/models/task.dart
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/foundation.dart'
    show immutable, listEquals, mapEquals, setEquals;
import 'package:recordapp/features/tasks/domain/models/alarm_type.dart';
import 'package:recordapp/features/tasks/domain/models/repeat_type.dart';

/// Misión o nota. Modelo inmutable escrito a mano (sin Freezed ni
/// json_serializable): no necesita generación de código.
///
/// Sonido de la alerta (solo con [AlarmType.sonido]):
/// - [sonidoUri] no vacío: audio propio del usuario (URI de MediaStore) y
///   [sonidoNombre] es su nombre visible.
/// - si no, [sonido] es el nombre de un archivo de `assets/audio/`
///   (vacío = el predeterminado).
///
/// [duracionSeg]: 0 = el sonido suena una vez, con la duración del audio;
/// mayor que 0 = el sonido se repite hasta completar esos segundos.
///
/// [fechaCreacion]: instante de creación en ISO-8601 (hora local), ancla de
/// los recordatorios periódicos de 5 h.
///
/// Repetición automática de la alarma (solo con sonido o vibración):
/// - [repeatCount]: cuántas veces más se repite la alerta tras la primera
///   (0 = desactivada).
/// - [intervalMinutes]: minutos entre una alerta y la siguiente.
/// Las repeticiones se detienen al completar, editar o eliminar la misión.
///
/// Rutinas (misiones que se repiten):
/// - [repeatType] `weekly`: se repite en los días de [repeatDays] (1 = lunes
///   … 7 = domingo, como `DateTime.weekday`). `fechaLimite` queda vacía.
/// - [repeatType] `customDates`: solo en las fechas de [customDates]
///   (`YYYY-MM-DD`).
/// - [horaLimite] es la **hora principal**: la de todos los días o fechas que
///   no tengan una hora propia.
/// - [repeatTimes] son los bloques de horario secundarios: asigna otra hora
///   (`HH:mm`) a días o fechas concretos. La clave es el día de la semana
///   (`"1"`…`"7"`) en rutinas semanales o la fecha (`YYYY-MM-DD`) en fechas
///   especiales. Ejemplo: `{"1":"08:00","2":"08:00","3":"10:30"}`.
/// - [doneDates]: historial de ejecuciones marcadas como hechas
///   (`YYYY-MM-DD`). La ocurrencia de un día está cumplida si ese día está en
///   el conjunto; por eso el check "se desmarca solo" al día siguiente.
///
/// Las claves de [toJson]/[Task.fromJson] son las columnas de `tareas`;
/// `repeat_days`, `custom_dates` y `done_dates` se guardan como texto separado
/// por comas y `repeat_times` como JSON.
@immutable
class Task {
  const Task({
    this.id,
    required this.titulo,
    this.descripcion = '',
    this.fechaLimite = '',
    this.horaLimite = '',
    this.tipoAlarma = AlarmType.sonido,
    this.sonido = '',
    this.sonidoUri = '',
    this.sonidoNombre = '',
    this.duracionSeg = 0,
    this.fechaCreacion = '',
    this.categoriaId = 'NOTAS',
    this.completada = false,
    this.repeatType = RepeatType.none,
    this.repeatDays = const <int>{},
    this.customDates = const <String>[],
    this.repeatTimes = const <String, String>{},
    this.doneDates = const <String>{},
    this.repeatCount = 0,
    this.intervalMinutes = 0,
  });

  factory Task.fromJson(Map<String, Object?> json) {
    String texto(String clave, [String porDefecto = '']) {
      final Object? valor = json[clave];
      return valor is String ? valor : porDefecto;
    }

    List<String> lista(String clave) => texto(clave)
        .split(',')
        .map((String f) => f.trim())
        .where((String f) => f.isNotEmpty)
        .toList();

    final Object? id = json['id'];
    final Object? completada = json['completada'];
    final Object? duracion = json['duracion_seg'];
    final Object? reintentos = json['repeat_count'];
    final Object? intervalo = json['interval_minutes'];
    final String alarma = texto('tipo_alarma');

    final Set<int> dias = lista('repeat_days')
        .map(int.tryParse)
        .whereType<int>()
        .where((int d) => d >= 1 && d <= 7)
        .toSet();

    final Map<String, String> horarios = <String, String>{};
    final String crudo = texto('repeat_times');
    if (crudo.isNotEmpty) {
      try {
        final Object? decodificado = jsonDecode(crudo);
        if (decodificado is Map) {
          decodificado.forEach((Object? k, Object? v) {
            if (k is String && v is String) horarios[k] = v;
          });
        }
      } on FormatException {
        // JSON corrupto: se ignora y se usa la hora principal.
      }
    }

    return Task(
      id: id is int ? id : null,
      titulo: texto('titulo'),
      descripcion: texto('descripcion'),
      fechaLimite: texto('fecha_limite'),
      horaLimite: texto('hora_limite'),
      tipoAlarma: AlarmType.values.firstWhere(
        (AlarmType t) => t.value == alarma,
        orElse: () => AlarmType.sonido,
      ),
      sonido: texto('sonido'),
      sonidoUri: texto('sonido_uri'),
      sonidoNombre: texto('sonido_nombre'),
      duracionSeg: duracion is num ? duracion.toInt() : 0,
      fechaCreacion: texto('fecha_creacion'),
      categoriaId: texto('categoria_id', 'NOTAS'),
      completada: completada == 1 || completada == true,
      repeatType: RepeatType.fromValue(texto('repeat_type', 'none')),
      repeatDays: dias,
      customDates: lista('custom_dates'),
      repeatTimes: horarios,
      doneDates: lista('done_dates').toSet(),
      repeatCount: reintentos is num ? reintentos.toInt() : 0,
      intervalMinutes: intervalo is num ? intervalo.toInt() : 0,
    );
  }

  final int? id;
  final String titulo;
  final String descripcion;
  final String fechaLimite;
  final String horaLimite;
  final AlarmType tipoAlarma;
  final String sonido;
  final String sonidoUri;
  final String sonidoNombre;
  final int duracionSeg;
  final String fechaCreacion;
  final String categoriaId;
  final bool completada;
  final RepeatType repeatType;
  final Set<int> repeatDays;
  final List<String> customDates;
  final Map<String, String> repeatTimes;
  final Set<String> doneDates;
  final int repeatCount;
  final int intervalMinutes;

  /// true si la misión se repite (rutina).
  bool get esRutina => repeatType != RepeatType.none;

  Map<String, Object?> toJson() {
    final List<String> clavesHorario = repeatTimes.keys.toList()..sort();
    return <String, Object?>{
      if (id != null) 'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_limite': fechaLimite,
      'hora_limite': horaLimite,
      'tipo_alarma': tipoAlarma.value,
      'sonido': sonido,
      'sonido_uri': sonidoUri,
      'sonido_nombre': sonidoNombre,
      'duracion_seg': duracionSeg,
      'fecha_creacion': fechaCreacion,
      'categoria_id': categoriaId,
      'completada': completada ? 1 : 0,
      'repeat_type': repeatType.value,
      'repeat_days': (repeatDays.toList()..sort()).join(','),
      'custom_dates': (customDates.toList()..sort()).join(','),
      'repeat_times': repeatTimes.isEmpty
          ? ''
          : jsonEncode(<String, String>{
              for (final String k in clavesHorario) k: repeatTimes[k]!,
            }),
      'done_dates': (doneDates.toList()..sort()).join(','),
      'repeat_count': repeatCount,
      'interval_minutes': intervalMinutes,
    };
  }

  Task copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? fechaLimite,
    String? horaLimite,
    AlarmType? tipoAlarma,
    String? sonido,
    String? sonidoUri,
    String? sonidoNombre,
    int? duracionSeg,
    String? fechaCreacion,
    String? categoriaId,
    bool? completada,
    RepeatType? repeatType,
    Set<int>? repeatDays,
    List<String>? customDates,
    Map<String, String>? repeatTimes,
    Set<String>? doneDates,
    int? repeatCount,
    int? intervalMinutes,
  }) {
    return Task(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      horaLimite: horaLimite ?? this.horaLimite,
      tipoAlarma: tipoAlarma ?? this.tipoAlarma,
      sonido: sonido ?? this.sonido,
      sonidoUri: sonidoUri ?? this.sonidoUri,
      sonidoNombre: sonidoNombre ?? this.sonidoNombre,
      duracionSeg: duracionSeg ?? this.duracionSeg,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      categoriaId: categoriaId ?? this.categoriaId,
      completada: completada ?? this.completada,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      customDates: customDates ?? this.customDates,
      repeatTimes: repeatTimes ?? this.repeatTimes,
      doneDates: doneDates ?? this.doneDates,
      repeatCount: repeatCount ?? this.repeatCount,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          other.id == id &&
          other.titulo == titulo &&
          other.descripcion == descripcion &&
          other.fechaLimite == fechaLimite &&
          other.horaLimite == horaLimite &&
          other.tipoAlarma == tipoAlarma &&
          other.sonido == sonido &&
          other.sonidoUri == sonidoUri &&
          other.sonidoNombre == sonidoNombre &&
          other.duracionSeg == duracionSeg &&
          other.fechaCreacion == fechaCreacion &&
          other.categoriaId == categoriaId &&
          other.completada == completada &&
          other.repeatType == repeatType &&
          setEquals(other.repeatDays, repeatDays) &&
          listEquals(other.customDates, customDates) &&
          mapEquals(other.repeatTimes, repeatTimes) &&
          setEquals(other.doneDates, doneDates) &&
          other.repeatCount == repeatCount &&
          other.intervalMinutes == intervalMinutes;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        titulo,
        descripcion,
        fechaLimite,
        horaLimite,
        tipoAlarma,
        sonido,
        sonidoUri,
        sonidoNombre,
        duracionSeg,
        fechaCreacion,
        categoriaId,
        completada,
        repeatType,
        Object.hashAllUnordered(repeatDays),
        Object.hashAll(customDates),
        Object.hashAllUnordered(
          repeatTimes.entries.map(
            (MapEntry<String, String> e) => Object.hash(e.key, e.value),
          ),
        ),
        Object.hashAllUnordered(doneDates),
        repeatCount,
        intervalMinutes,
      ]);

  @override
  String toString() => 'Task(id: $id, titulo: $titulo, categoria: $categoriaId, '
      'limite: $fechaLimite $horaLimite, alarma: ${tipoAlarma.value}, '
      'repite: ${repeatType.value})';
}