// lib/features/tasks/domain/services/time_formatter.dart

/// Utilidades de fecha/hora. Formato interno de persistencia:
/// fecha `YYYY-MM-DD` y hora `HH:mm` (24h).
abstract final class TimeFormatter {
  static final RegExp _fechaRegExp = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final RegExp _horaRegExp = RegExp(r'^(\d{1,2}):(\d{2})$');

  static String _dos(int valor) => valor.toString().padLeft(2, '0');

  /// `YYYY-MM-DD`
  static String fechaDb(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${_dos(fecha.month)}-${_dos(fecha.day)}';

  /// `HH:mm`
  static String horaDb(DateTime fecha) =>
      '${_dos(fecha.hour)}:${_dos(fecha.minute)}';

  /// Convierte fecha y hora almacenadas en un [DateTime]. Si la hora está vacía
  /// se asume el final del día (23:59). Devuelve null si no hay fecha o es inválida.
  static DateTime? parseLimite(String fecha, String hora) {
    final String f = fecha.trim();
    if (f.isEmpty) return null;

    final RegExpMatch? fechaMatch = _fechaRegExp.firstMatch(f);
    if (fechaMatch == null) return null;

    final int year = int.parse(fechaMatch.group(1)!);
    final int month = int.parse(fechaMatch.group(2)!);
    final int day = int.parse(fechaMatch.group(3)!);

    int horas = 23;
    int minutos = 59;
    final String h = hora.trim();
    if (h.isNotEmpty) {
      final RegExpMatch? horaMatch = _horaRegExp.firstMatch(h);
      if (horaMatch == null) return null;
      horas = int.parse(horaMatch.group(1)!);
      minutos = int.parse(horaMatch.group(2)!);
      if (horas > 23 || minutos > 59) return null;
    }

    final DateTime resultado = DateTime(year, month, day, horas, minutos);
    if (resultado.month != month || resultado.day != day) return null;
    return resultado;
  }

  /// Indica si el límite ya pasó respecto a [ahora] (por defecto, el instante actual).
  static bool estaVencida(String fecha, String hora, {DateTime? ahora}) {
    final DateTime? limite = parseLimite(fecha, hora);
    if (limite == null) return false;
    return (ahora ?? DateTime.now()).isAfter(limite);
  }

  /// Formatea una hora `HH:mm` a 24h o 12h (AM/PM).
  static String formatearHora(String hora, {required bool formato24h}) {
    final String h = hora.trim();
    if (h.isEmpty) return '';

    final RegExpMatch? match = _horaRegExp.firstMatch(h);
    if (match == null) return h;

    final int horas = int.parse(match.group(1)!);
    final int minutos = int.parse(match.group(2)!);
    if (horas > 23 || minutos > 59) return h;

    if (formato24h) return '${_dos(horas)}:${_dos(minutos)}';

    final String sufijo = horas >= 12 ? 'PM' : 'AM';
    final int horas12 = horas % 12 == 0 ? 12 : horas % 12;
    return '${_dos(horas12)}:${_dos(minutos)} $sufijo';
  }

  /// Formatea una fecha `YYYY-MM-DD` según un patrón con tokens `YYYY`, `MM`, `DD`.
  static String formatearFecha(String fecha, {String patron = 'YYYY-MM-DD'}) {
    final String f = fecha.trim();
    if (f.isEmpty) return '';

    final RegExpMatch? match = _fechaRegExp.firstMatch(f);
    if (match == null) return f;

    return patron
        .replaceAll('YYYY', match.group(1)!)
        .replaceAll('MM', match.group(2)!)
        .replaceAll('DD', match.group(3)!);
  }
}
