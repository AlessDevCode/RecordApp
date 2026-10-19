// test/status_summary_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recordapp/features/tasks/domain/models/repeat_type.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/services/status_summary.dart';

void main() {
  // 2026-10-14 es miércoles.
  final DateTime ahora = DateTime(2026, 10, 14, 10, 0);

  Task normal(int id, String fecha, String hora, {bool completada = false}) =>
      Task(
        id: id,
        titulo: 'M$id',
        fechaLimite: fecha,
        horaLimite: hora,
        completada: completada,
      );

  Task semanal({
    Set<String> hechas = const <String>{},
    Map<String, String> horarios = const <String, String>{},
  }) =>
      Task(
        id: 5,
        titulo: 'Gym',
        horaLimite: '18:00',
        repeatType: RepeatType.weekly,
        repeatDays: const <int>{3}, // miércoles
        repeatTimes: horarios,
        doneDates: hechas,
      );

  group('StatusSummaryService', () {
    test('sin misiones: nada pendiente', () {
      final StatusSummary r =
          StatusSummaryService.calcular(const <Task>[], ahora: ahora);
      expect(r.tipo, StatusKind.ninguna);
      expect(r.pendientes, 0);
      expect(r.tarea, isNull);
    });

    test('elige la próxima por venir y cuenta las pendientes', () {
      final StatusSummary r = StatusSummaryService.calcular(
        <Task>[
          normal(1, '2026-10-15', '09:00'),
          normal(2, '2026-10-14', '15:00'),
        ],
        ahora: ahora,
      );
      expect(r.tipo, StatusKind.proxima);
      expect(r.tarea?.id, 2);
      expect(r.cuando, DateTime(2026, 10, 14, 15, 0));
      expect(r.pendientes, 2);
    });

    test('ignora las completadas y las notas sin fecha', () {
      final StatusSummary r = StatusSummaryService.calcular(
        <Task>[
          normal(1, '2026-10-14', '15:00', completada: true),
          const Task(id: 2, titulo: 'nota'),
        ],
        ahora: ahora,
      );
      expect(r.tipo, StatusKind.ninguna);
    });

    test('una misión que acaba de vencer (≤ 30 min) pasa a "ahora"', () {
      final StatusSummary r = StatusSummaryService.calcular(
        <Task>[normal(1, '2026-10-14', '09:45')],
        ahora: ahora,
      );
      expect(r.tipo, StatusKind.ahora);
      expect(r.tarea?.id, 1);
      expect(r.cuando, DateTime(2026, 10, 14, 9, 45));
    });

    test('vencida hace más de 30 min ya no ocupa la notificación', () {
      final StatusSummary r = StatusSummaryService.calcular(
        <Task>[normal(1, '2026-10-14', '09:29')],
        ahora: ahora,
      );
      expect(r.tipo, StatusKind.ninguna);
    });

    test('rutina: próxima ocurrencia de hoy y, si ya está hecha, la siguiente', () {
      final StatusSummary hoy =
          StatusSummaryService.calcular(<Task>[semanal()], ahora: ahora);
      expect(hoy.tipo, StatusKind.proxima);
      expect(hoy.cuando, DateTime(2026, 10, 14, 18, 0));

      final StatusSummary hecha = StatusSummaryService.calcular(
        <Task>[semanal(hechas: <String>{'2026-10-14'})],
        ahora: ahora,
      );
      expect(hecha.cuando, DateTime(2026, 10, 21, 18, 0));
    });

    test('rutina: usa la hora del bloque del día', () {
      final StatusSummary r = StatusSummaryService.calcular(
        <Task>[semanal(horarios: const <String, String>{'3': '10:30'})],
        ahora: ahora,
      );
      expect(r.cuando, DateTime(2026, 10, 14, 10, 30));
    });

    test('"ahora" tiene prioridad sobre la próxima', () {
      final StatusSummary r = StatusSummaryService.calcular(
        <Task>[semanal(), normal(2, '2026-10-15', '09:00')],
        ahora: DateTime(2026, 10, 14, 18, 10),
      );
      expect(r.tipo, StatusKind.ahora);
      expect(r.tarea?.id, 5);
      expect(r.cuando, DateTime(2026, 10, 14, 18, 0));
      // Pendientes: la próxima ocurrencia de la rutina y la misión del día 15.
      expect(r.pendientes, 2);
    });

    test('pasada la ventana de 30 min vuelve a mostrarse la próxima', () {
      final StatusSummary r = StatusSummaryService.calcular(
        <Task>[semanal(), normal(2, '2026-10-15', '09:00')],
        ahora: DateTime(2026, 10, 14, 18, 31),
      );
      expect(r.tipo, StatusKind.proxima);
      expect(r.tarea?.id, 2);
      expect(r.pendientes, 2);
    });
  });
}