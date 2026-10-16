// test/reminder_planner_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';
import 'package:recordapp/features/alarms/domain/services/reminder_planner.dart';

void main() {
  final DateTime t0 = DateTime(2026, 10, 8, 10, 0);

  group('ReminderPlanner.planificar', () {
    test('misión de 3d 4h: 5h hasta las últimas 6h, luego 90 min, y final', () {
      final DateTime limite = t0.add(const Duration(days: 3, hours: 4));
      final List<PlannedAlert> a = ReminderPlanner.planificar(
        idMision: 7,
        creacion: t0,
        limite: limite,
        ahora: t0,
      );

      final List<PlannedAlert> normales =
          a.where((PlannedAlert x) => x.tipo == AlertKind.recordatorio).toList();
      final List<PlannedAlert> urgentes =
          a.where((PlannedAlert x) => x.tipo == AlertKind.urgente).toList();
      final List<PlannedAlert> finales =
          a.where((PlannedAlert x) => x.tipo == AlertKind.finalizacion).toList();

      // 5h·k < 70h (límite - 6h = 70h tras la creación) -> k = 1..13
      expect(normales.length, 13);
      expect(normales.first.cuando, t0.add(const Duration(hours: 5)));
      expect(
        ReminderPlanner.formatearRestante(normales.first.restante),
        '2d 23h',
      );

      expect(urgentes.map((PlannedAlert x) => x.restante).toList(), <Duration>[
        const Duration(hours: 6),
        const Duration(hours: 4, minutes: 30),
        const Duration(hours: 3),
        const Duration(hours: 1, minutes: 30),
      ]);

      expect(finales.length, 1);
      expect(finales.single.cuando, limite);
      expect(finales.single.id, 700);
    });

    test('creada con menos de 6h: solo urgentes futuras y final', () {
      final DateTime ahora = t0;
      final DateTime limite = ahora.add(const Duration(hours: 2));
      final List<PlannedAlert> a = ReminderPlanner.planificar(
        idMision: 1,
        creacion: ahora.subtract(const Duration(hours: 1)),
        limite: limite,
        ahora: ahora,
      );
      expect(
        a.where((PlannedAlert x) => x.tipo == AlertKind.recordatorio),
        isEmpty,
      );
      // Rejilla: límite-6h, -4h30, -3h, -1h30 -> solo la última es futura.
      expect(
        a.where((PlannedAlert x) => x.tipo == AlertKind.urgente).length,
        1,
      );
      expect(a.last.tipo, AlertKind.finalizacion);
    });

    test('límite pasado: nada que programar', () {
      expect(
        ReminderPlanner.planificar(
          idMision: 1,
          creacion: t0,
          limite: t0.subtract(const Duration(minutes: 1)),
          ahora: t0,
        ),
        isEmpty,
      );
    });

    test('respeta el tope de recordatorios normales', () {
      final List<PlannedAlert> a = ReminderPlanner.planificar(
        idMision: 1,
        creacion: t0,
        limite: t0.add(const Duration(days: 60)),
        ahora: t0,
      );
      expect(
        a.where((PlannedAlert x) => x.tipo == AlertKind.recordatorio).length,
        ReminderPlanner.maxNormalesPorMision,
      );
    });
  });

  group('formatearRestante', () {
    test('formatos', () {
      expect(
        ReminderPlanner.formatearRestante(const Duration(hours: 27)),
        '1d 3h',
      );
      expect(
        ReminderPlanner.formatearRestante(const Duration(hours: 22, minutes: 17)),
        '22h',
      );
      expect(
        ReminderPlanner.formatearRestante(
          const Duration(hours: 1, minutes: 30),
          detallado: true,
        ),
        '1h 30m',
      );
      expect(ReminderPlanner.formatearRestante(const Duration(days: 2)), '2d');
    });
  });

  group('AlertSound', () {
    test('nombre de recurso raw y etiqueta', () {
      const AlertSound s = AlertSound(
        fileName: 'Alerta Neón.mp3',
        assetPath: 'assets/audio/Alerta Neón.mp3',
      );
      expect(s.rawResourceName, 'alerta_ne_n_mp3');
      expect(s.label, 'Alerta Neón');
      expect(s.playerSource, 'audio/Alerta Neón.mp3');
      expect(
        const AlertSound(fileName: '1up.wav', assetPath: 'assets/audio/1up.wav')
            .rawResourceName,
        's_1up_wav',
      );
    });

    test('resolverSonido: coincidencia, alert.mp3 y primero', () {
      const AlertSound a = AlertSound(fileName: 'a.mp3', assetPath: 'assets/audio/a.mp3');
      const AlertSound alert =
          AlertSound(fileName: 'alert.mp3', assetPath: 'assets/audio/alert.mp3');
      expect(resolverSonido(<AlertSound>[a, alert], 'a.mp3'), a);
      expect(resolverSonido(<AlertSound>[a, alert], 'borrado.mp3'), alert);
      expect(resolverSonido(<AlertSound>[a], ''), a);
      expect(resolverSonido(const <AlertSound>[], 'x'), isNull);
    });
  });
}
