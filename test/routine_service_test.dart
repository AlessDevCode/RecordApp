// test/routine_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recordapp/features/alarms/domain/services/reminder_planner.dart';
import 'package:recordapp/features/tasks/domain/models/completed_entry.dart';
import 'package:recordapp/features/tasks/domain/models/repeat_type.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/models/task_status_filter.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';
import 'package:recordapp/features/tasks/domain/services/task_filter_service.dart';

void main() {
  // 2026-10-14 es miércoles (weekday 3); 16 viernes; 19 lunes; 21 miércoles.
  final DateTime miercolesManana = DateTime(2026, 10, 14, 10, 0);

  Task semanal({
    Set<String> hechas = const <String>{},
    String hora = '18:00',
    Set<int> dias = const <int>{1, 3, 5}, // lunes, miércoles, viernes
    Map<String, String> horarios = const <String, String>{},
  }) =>
      Task(
        id: 5,
        titulo: 'Gimnasio',
        horaLimite: hora,
        categoriaId: 'SALUD',
        repeatType: RepeatType.weekly,
        repeatDays: dias,
        repeatTimes: horarios,
        doneDates: hechas,
      );

  Task especial({
    Set<String> hechas = const <String>{},
    Map<String, String> horarios = const <String, String>{},
  }) =>
      Task(
        id: 7,
        titulo: 'Examen',
        horaLimite: '09:00',
        repeatType: RepeatType.customDates,
        customDates: const <String>['2026-10-14', '2026-10-20'],
        repeatTimes: horarios,
        doneDates: hechas,
      );

  group('RoutineService.proximasEjecuciones', () {
    test('semanal L-X-V: hoy, viernes y lunes', () {
      final List<DateTime> r = RoutineService.proximasEjecuciones(
        semanal(),
        desde: miercolesManana,
        max: 3,
      );
      expect(r, <DateTime>[
        DateTime(2026, 10, 14, 18, 0),
        DateTime(2026, 10, 16, 18, 0),
        DateTime(2026, 10, 19, 18, 0),
      ]);
    });

    test('marcada hoy: la siguiente es el viernes', () {
      final DateTime? proxima = RoutineService.proximaEjecucion(
        semanal(hechas: <String>{'2026-10-14'}),
        ahora: miercolesManana,
      );
      expect(proxima, DateTime(2026, 10, 16, 18, 0));
    });

    test('si hoy ya pasó la hora, la siguiente es el viernes', () {
      final DateTime? proxima = RoutineService.proximaEjecucion(
        semanal(),
        ahora: DateTime(2026, 10, 14, 19, 0),
      );
      expect(proxima, DateTime(2026, 10, 16, 18, 0));
    });

    test('fechas especiales: ignora las pasadas', () {
      final List<DateTime> r = RoutineService.proximasEjecuciones(
        especial(),
        desde: DateTime(2026, 10, 14, 10, 0),
      );
      expect(r, <DateTime>[DateTime(2026, 10, 20, 9, 0)]);
    });

    test('semanal sin días o misión normal: nada que programar', () {
      expect(
        RoutineService.proximasEjecuciones(
          semanal(dias: const <int>{}),
          desde: miercolesManana,
        ),
        isEmpty,
      );
      expect(
        RoutineService.proximasEjecuciones(
          const Task(titulo: 'x', fechaLimite: '2026-10-20'),
          desde: miercolesManana,
        ),
        isEmpty,
      );
    });
  });

  group('Horarios distintos por día', () {
    test('cada día usa la hora de su bloque', () {
      final List<DateTime> r = RoutineService.proximasEjecuciones(
        semanal(
          dias: const <int>{1, 3},
          horarios: const <String, String>{'1': '08:00', '3': '10:30'},
        ),
        desde: DateTime(2026, 10, 14, 9, 0),
        max: 3,
      );
      expect(r, <DateTime>[
        DateTime(2026, 10, 14, 10, 30),
        DateTime(2026, 10, 19, 8, 0),
        DateTime(2026, 10, 21, 10, 30),
      ]);
    });

    test('los días sin bloque usan la hora principal', () {
      final List<DateTime> r = RoutineService.proximasEjecuciones(
        semanal(horarios: const <String, String>{'1': '08:00'}),
        desde: miercolesManana,
        max: 3,
      );
      expect(r, <DateTime>[
        DateTime(2026, 10, 14, 18, 0),
        DateTime(2026, 10, 16, 18, 0),
        DateTime(2026, 10, 19, 8, 0),
      ]);
    });

    test('una hora inválida se ignora y se usa la principal', () {
      final DateTime? proxima = RoutineService.proximaEjecucion(
        semanal(horarios: const <String, String>{'3': '25:99'}),
        ahora: miercolesManana,
      );
      expect(proxima, DateTime(2026, 10, 14, 18, 0));
    });

    test('fechas especiales con hora propia', () {
      final List<DateTime> r = RoutineService.proximasEjecuciones(
        especial(horarios: const <String, String>{'2026-10-20': '07:15'}),
        desde: DateTime(2026, 10, 14, 10, 0),
      );
      expect(r, <DateTime>[DateTime(2026, 10, 20, 7, 15)]);
    });

    test('horaDe: bloque del día o principal', () {
      final Task t = semanal(horarios: const <String, String>{'3': '10:30'});
      expect(RoutineService.horaDe(t, DateTime(2026, 10, 14)), '10:30');
      expect(RoutineService.horaDe(t, DateTime(2026, 10, 16)), '18:00');
    });

    test('el planificador programa cada alarma a su hora exacta', () {
      final List<MissionPlan> planes = ReminderPlanner.planificarTareas(
        <Task>[
          semanal(
            dias: const <int>{1, 3},
            horarios: const <String, String>{'1': '08:00', '3': '10:30'},
          ),
        ],
        ahora: DateTime(2026, 10, 14, 9, 0),
      );
      final List<PlannedAlert> a = planes.single.alertas;
      expect(a[0].cuando, DateTime(2026, 10, 14, 10, 30));
      expect(a[1].cuando, DateTime(2026, 10, 19, 8, 0));
      expect(a[0].id, 500);
      expect(a[1].id, 501);
      expect(a.every((PlannedAlert x) => x.tipo == AlertKind.finalizacion), isTrue);
    });
  });

  group('Estado CRÍTICO de las rutinas (ventana de 30 min)', () {
    // Rutina semanal L-X-V a las 18:00; 2026-10-14 es miércoles.
    DateTime miercoles(int h, int m, [int sg = 0]) =>
        DateTime(2026, 10, 14, h, m, sg);

    test('crítica solo entre la hora programada y 30 minutos después', () {
      final Task t = semanal();
      expect(RoutineService.estaVencida(t, ahora: miercoles(17, 59)), isFalse);
      expect(RoutineService.estaVencida(t, ahora: miercoles(18, 0)), isTrue);
      expect(RoutineService.estaVencida(t, ahora: miercoles(18, 15)), isTrue);
      expect(RoutineService.estaVencida(t, ahora: miercoles(18, 30)), isTrue);
      expect(RoutineService.estaVencida(t, ahora: miercoles(18, 30, 1)), isFalse);
      expect(RoutineService.estaVencida(t, ahora: miercoles(23, 0)), isFalse);
    });

    test('pasada la ventana, la tarjeta muestra la siguiente ocurrencia', () {
      final DateTime ahora = miercoles(18, 31);
      expect(RoutineService.estaVencida(semanal(), ahora: ahora), isFalse);
      expect(
        RoutineService.proximaEjecucion(semanal(), ahora: ahora),
        DateTime(2026, 10, 16, 18, 0),
      );
    });

    test('hecha dentro de la ventana: deja de ser crítica', () {
      expect(
        RoutineService.estaVencida(
          semanal(hechas: <String>{'2026-10-14'}),
          ahora: miercoles(18, 10),
        ),
        isFalse,
      );
    });

    test('hoy no toca (martes): no es crítica', () {
      expect(
        RoutineService.estaVencida(semanal(), ahora: DateTime(2026, 10, 13, 18, 10)),
        isFalse,
      );
    });

    test('usa la hora del bloque del día', () {
      final Task t = semanal(horarios: const <String, String>{'3': '09:00'});
      expect(RoutineService.estaVencida(t, ahora: miercoles(9, 10)), isTrue);
      expect(RoutineService.estaVencida(t, ahora: miercoles(10, 0)), isFalse);
      // Sin bloque propio, a las 09:10 todavía no llega su hora (18:00).
      expect(RoutineService.estaVencida(semanal(), ahora: miercoles(9, 10)), isFalse);
    });

    test('fechas especiales: solo 30 min y sin dejar alertas fantasma', () {
      final Task t = especial(); // 14 y 20 de octubre a las 09:00
      expect(RoutineService.estaVencida(t, ahora: DateTime(2026, 10, 14, 9, 10)), isTrue);
      expect(RoutineService.estaVencida(t, ahora: DateTime(2026, 10, 14, 10, 0)), isFalse);
      expect(RoutineService.estaVencida(t, ahora: DateTime(2026, 10, 15, 9, 10)), isFalse);
      expect(
        RoutineService.proximaEjecucion(t, ahora: DateTime(2026, 10, 15, 10, 0)),
        DateTime(2026, 10, 20, 9, 0),
      );
    });

    test('marcarla hoy limpia el estado y la próxima ocurrencia avanza', () {
      final Task hecha = especial(hechas: <String>{'2026-10-14'});
      final DateTime ahora = DateTime(2026, 10, 14, 9, 10);
      expect(RoutineService.estaVencida(hecha, ahora: ahora), isFalse);
      expect(RoutineService.proximaEjecucion(hecha, ahora: ahora), DateTime(2026, 10, 20, 9, 0));
    });

    test('una misión normal vencida sigue en crítico', () {
      const Task normal = Task(
        id: 1,
        titulo: 'normal',
        fechaLimite: '2026-10-01',
        horaLimite: '10:00',
      );
      expect(RoutineService.estaVencida(normal, ahora: miercoles(12, 0)), isTrue);
    });
  });

  group('Historial', () {
    test('ejecuciones de la más reciente a la más antigua', () {
      final Task t = semanal(
        hechas: <String>{'2026-10-10', '2026-10-14', '2026-10-12'},
      );
      expect(RoutineService.historial(t), <String>[
        '2026-10-14',
        '2026-10-12',
        '2026-10-10',
      ]);
      expect(RoutineService.historial(t, max: 2), <String>[
        '2026-10-14',
        '2026-10-12',
      ]);
    });

    test('hechaHoy depende del historial', () {
      expect(
        RoutineService.hechaHoy(
          semanal(hechas: <String>{'2026-10-14'}),
          ahora: miercolesManana,
        ),
        isTrue,
      );
      expect(
        RoutineService.hechaHoy(
          semanal(hechas: <String>{'2026-10-13'}),
          ahora: miercolesManana,
        ),
        isFalse,
      );
    });
  });

  group('Task (JSON)', () {
    test('ida y vuelta con horarios por día e historial', () {
      final Task original = semanal(
        hechas: <String>{'2026-10-14', '2026-10-12'},
        horarios: const <String, String>{'3': '10:30', '1': '08:00'},
      ).copyWith(customDates: <String>['2026-11-02', '2026-10-30']);

      final Map<String, Object?> json = original.toJson();
      expect(json['repeat_type'], 'weekly');
      expect(json['repeat_days'], '1,3,5');
      expect(json['custom_dates'], '2026-10-30,2026-11-02');
      expect(json['repeat_times'], '{"1":"08:00","3":"10:30"}');
      expect(json['done_dates'], '2026-10-12,2026-10-14');

      final Task leida = Task.fromJson(json);
      expect(leida.repeatTimes, <String, String>{'1': '08:00', '3': '10:30'});
      expect(leida.doneDates, <String>{'2026-10-12', '2026-10-14'});
      expect(leida, original.copyWith(customDates: <String>['2026-10-30', '2026-11-02']));
    });

    test('JSON de horarios corrupto se ignora; last_done heredado no se lee', () {
      final Task t = Task.fromJson(<String, Object?>{
        'titulo': 'x',
        'repeat_times': '{no es json',
        'last_done': '2026-10-14',
      });
      expect(t.repeatTimes, isEmpty);
      expect(t.doneDates, isEmpty);
    });

    test('filas antiguas (sin columnas de rutina) son misiones normales', () {
      final Task t = Task.fromJson(<String, Object?>{'titulo': 'vieja'});
      expect(t.esRutina, isFalse);
      expect(t.repeatDays, isEmpty);
      expect(t.repeatTimes, isEmpty);
    });
  });

  group('ReminderPlanner con rutinas', () {
    test('hasta 14 ocurrencias, solo finalización, ids idMision*100+i', () {
      final List<MissionPlan> planes = ReminderPlanner.planificarTareas(
        <Task>[semanal()],
        ahora: miercolesManana,
      );
      final List<PlannedAlert> a = planes.single.alertas;
      expect(a.length, RoutineService.maxEjecuciones);
      expect(a.first.id, 500);
      expect(a.first.cuando, DateTime(2026, 10, 14, 18, 0));
    });

    test('una rutina archivada no se programa', () {
      expect(
        ReminderPlanner.planificarTareas(
          <Task>[semanal().copyWith(completada: true)],
          ahora: miercolesManana,
        ),
        isEmpty,
      );
    });
  });

  group('TaskFilterService', () {
    const Task normal = Task(id: 1, titulo: 'normal', fechaLimite: '2026-12-01');

    test('RUTINAS deja solo las rutinas', () {
      final List<Task> r = TaskFilterService.filtrar(
        <Task>[normal, semanal()],
        estados: <TaskStatusFilter>{TaskStatusFilter.rutinas},
        ahora: miercolesManana,
      );
      expect(r.map((Task t) => t.id), <int?>[5]);
    });

    test('RUTINAS + CRÍTICO = rutinas vencidas', () {
      final List<Task> r = TaskFilterService.filtrar(
        <Task>[
          normal,
          semanal(),
          semanal(hechas: <String>{'2026-10-14'}).copyWith(id: 6),
        ],
        estados: <TaskStatusFilter>{
          TaskStatusFilter.rutinas,
          TaskStatusFilter.critico,
        },
        ahora: DateTime(2026, 10, 14, 18, 10),
      );
      expect(r.map((Task t) => t.id), <int?>[5]);
    });

    test('COMPLETADAS: normales finalizadas + historial de rutinas, recientes primero', () {
      final List<Task> tareas = <Task>[
        const Task(id: 1, titulo: 'vieja', fechaLimite: '2026-10-01', completada: true),
        const Task(id: 2, titulo: 'pendiente', fechaLimite: '2026-12-01'),
        semanal(hechas: <String>{'2026-10-12', '2026-10-14'}),
      ];

      final List<CompletedEntry> todas = TaskFilterService.entradasCompletadas(tareas);
      expect(
        todas.map((CompletedEntry e) => '${e.tarea.id}:${e.fecha}').toList(),
        <String>['5:2026-10-14', '5:2026-10-12', '1:null'],
      );

      final List<CompletedEntry> soloRutinas =
          TaskFilterService.entradasCompletadas(tareas, soloRutinas: true);
      expect(soloRutinas.every((CompletedEntry e) => e.esEjecucion), isTrue);
      expect(soloRutinas.length, 2);

      final List<CompletedEntry> deSalud =
          TaskFilterService.entradasCompletadas(tareas, categoria: 'salud');
      expect(deSalud.map((CompletedEntry e) => e.tarea.id).toSet(), <int?>{5});
    });
  });
}