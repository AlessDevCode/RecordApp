// test/alarm_repeat_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recordapp/features/alarms/domain/services/reminder_planner.dart';
import 'package:recordapp/features/tasks/domain/models/repeat_type.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';

void main() {
  // 2026-10-14 es miércoles.
  final DateTime t0 = DateTime(2026, 10, 14, 10, 0);
  final DateTime limite = DateTime(2026, 10, 14, 12, 0);

  List<PlannedAlert> repeticiones(List<PlannedAlert> a) =>
      a.where((PlannedAlert x) => x.tipo == AlertKind.repeticion).toList();

  group('Repeticiones de una misión', () {
    test('3 repeticiones cada 5 min después de la alerta final', () {
      final List<PlannedAlert> a = ReminderPlanner.planificar(
        idMision: 9,
        creacion: t0,
        limite: limite,
        ahora: t0,
        repeticiones: 3,
        intervaloMin: 5,
      );
      final List<PlannedAlert> r = repeticiones(a);
      expect(r.map((PlannedAlert x) => x.cuando).toList(), <DateTime>[
        DateTime(2026, 10, 14, 12, 5),
        DateTime(2026, 10, 14, 12, 10),
        DateTime(2026, 10, 14, 12, 15),
      ]);
      expect(r.map((PlannedAlert x) => x.id).toList(), <int>[960, 961, 962]);
      expect(r.map((PlannedAlert x) => x.numero).toList(), <int>[1, 2, 3]);
      expect(r.every((PlannedAlert x) => x.total == 3), isTrue);
      // La alerta final sigue en su sitio, con su id de siempre.
      expect(
        a.any((PlannedAlert x) =>
            x.tipo == AlertKind.finalizacion && x.id == 900 && x.cuando == limite),
        isTrue,
      );
    });

    test('sin repeticiones o sin intervalo no se programa nada extra', () {
      expect(
        repeticiones(ReminderPlanner.planificar(
          idMision: 9,
          creacion: t0,
          limite: limite,
          ahora: t0,
        )),
        isEmpty,
      );
      expect(
        repeticiones(ReminderPlanner.planificar(
          idMision: 9,
          creacion: t0,
          limite: limite,
          ahora: t0,
          repeticiones: 3,
        )),
        isEmpty,
      );
    });

    test('el máximo es ${ReminderPlanner.maxRepeticiones} repeticiones', () {
      final List<PlannedAlert> r = repeticiones(ReminderPlanner.planificar(
        idMision: 9,
        creacion: t0,
        limite: limite,
        ahora: t0,
        repeticiones: 9,
        intervaloMin: 2,
      ));
      expect(r.length, ReminderPlanner.maxRepeticiones);
      expect(r.last.id, 964);
    });

    test('con el límite ya pasado siguen programadas las repeticiones pendientes', () {
      final List<PlannedAlert> a = ReminderPlanner.planificar(
        idMision: 9,
        creacion: t0,
        limite: limite,
        ahora: DateTime(2026, 10, 14, 12, 7),
        repeticiones: 3,
        intervaloMin: 5,
      );
      // La de las 12:05 ya sonó; quedan la 2.ª y la 3.ª con sus mismos ids.
      expect(a.map((PlannedAlert x) => x.id).toList(), <int>[961, 962]);
      expect(a.map((PlannedAlert x) => x.numero).toList(), <int>[2, 3]);
    });

    test('planificarTareas conserva las repeticiones de una misión vencida', () {
      const Task t = Task(
        id: 9,
        titulo: 'Pastilla',
        fechaLimite: '2026-10-14',
        horaLimite: '12:00',
        fechaCreacion: '2026-10-14T10:00:00.000',
        repeatCount: 3,
        intervalMinutes: 5,
      );
      final List<MissionPlan> pendientes = ReminderPlanner.planificarTareas(
        <Task>[t],
        ahora: DateTime(2026, 10, 14, 12, 7),
      );
      expect(
        pendientes.single.alertas.map((PlannedAlert x) => x.id).toList(),
        <int>[961, 962],
      );

      // Pasadas todas las repeticiones (12:15), ya no hay nada que programar.
      expect(
        ReminderPlanner.planificarTareas(
          <Task>[t],
          ahora: DateTime(2026, 10, 14, 12, 20),
        ),
        isEmpty,
      );
    });
  });

  group('Repeticiones de una rutina', () {
    Task semanal({Set<String> hechas = const <String>{}}) => Task(
          id: 5,
          titulo: 'Medicina',
          horaLimite: '18:00',
          repeatType: RepeatType.weekly,
          repeatDays: const <int>{3}, // miércoles
          repeatCount: 2,
          intervalMinutes: 10,
          doneDates: hechas,
        );

    test('cada ocurrencia tiene sus propias repeticiones, con ids distintos', () {
      final List<MissionPlan> planes = ReminderPlanner.planificarTareas(
        <Task>[semanal()],
        ahora: DateTime(2026, 10, 14, 18, 5),
      );
      final List<PlannedAlert> a = planes.single.alertas;

      // Hoy la alerta final ya sonó: quedan sus repeticiones de las 18:10 y 18:20.
      expect(a[0].tipo, AlertKind.repeticion);
      expect(a[0].cuando, DateTime(2026, 10, 14, 18, 10));
      expect(a[0].id, 514);
      expect(a[1].id, 515);

      // Después, la siguiente semana: final y sus dos repeticiones.
      expect(a[2].tipo, AlertKind.finalizacion);
      expect(a[2].cuando, DateTime(2026, 10, 21, 18, 0));
      expect(a[2].id, 501);
      expect(a[3].id, 519);
      expect(a[4].id, 520);

      expect(a.map((PlannedAlert x) => x.id).toSet().length, a.length);
    });

    test('marcada hoy: las repeticiones de hoy se cancelan', () {
      final List<MissionPlan> planes = ReminderPlanner.planificarTareas(
        <Task>[semanal(hechas: <String>{'2026-10-14'})],
        ahora: DateTime(2026, 10, 14, 18, 5),
      );
      final PlannedAlert primera = planes.single.alertas.first;
      expect(primera.tipo, AlertKind.finalizacion);
      expect(primera.cuando, DateTime(2026, 10, 21, 18, 0));
    });

    test('terminada su ventana de repeticiones, la ocurrencia ya no cuenta', () {
      final List<MissionPlan> planes = ReminderPlanner.planificarTareas(
        <Task>[semanal()],
        ahora: DateTime(2026, 10, 14, 18, 30),
      );
      final PlannedAlert primera = planes.single.alertas.first;
      expect(primera.tipo, AlertKind.finalizacion);
      expect(primera.cuando, DateTime(2026, 10, 21, 18, 0));
    });
  });

  group('Task (JSON)', () {
    test('ida y vuelta de repeat_count e interval_minutes', () {
      const Task original = Task(
        id: 1,
        titulo: 'x',
        repeatCount: 3,
        intervalMinutes: 5,
      );
      final Map<String, Object?> json = original.toJson();
      expect(json['repeat_count'], 3);
      expect(json['interval_minutes'], 5);
      expect(Task.fromJson(json), original);
    });

    test('filas antiguas no tienen repeticiones', () {
      final Task t = Task.fromJson(<String, Object?>{'titulo': 'vieja'});
      expect(t.repeatCount, 0);
      expect(t.intervalMinutes, 0);
    });
  });
}