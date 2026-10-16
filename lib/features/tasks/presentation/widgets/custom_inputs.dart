// lib/features/tasks/presentation/widgets/custom_inputs.dart
import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTextThemeData,
        CupertinoTheme,
        CupertinoThemeData;
import 'package:flutter/material.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';

/// Campo de fecha. [value] usa el formato interno `YYYY-MM-DD` ('' = vacío).
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.displayPattern = 'YYYY-MM-DD',
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String displayPattern;

  Future<void> _seleccionar(BuildContext context) async {
    final DateTime ahora = DateTime.now();
    final DateTime inicial = TimeFormatter.parseLimite(value, '') ?? ahora;

    final DateTime? elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(ahora.year + 20, 12, 31),
    );

    if (elegida != null) {
      onChanged(TimeFormatter.fechaDb(elegida));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String texto = value.isEmpty
        ? ''
        : TimeFormatter.formatearFecha(value, patron: displayPattern);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _seleccionar(context),
      child: InputDecorator(
        isEmpty: value.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: value.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(''),
                ),
        ),
        child: Text(texto),
      ),
    );
  }
}

/// Campo de hora. [value] usa el formato interno `HH:mm` ('' = vacío).
class TimePickerField extends StatelessWidget {
  const TimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.formato24h = true,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool formato24h;

  static final RegExp _horaRegExp = RegExp(r'^(\d{1,2}):(\d{2})$');

  TimeOfDay _inicial() {
    final RegExpMatch? match = _horaRegExp.firstMatch(value.trim());
    if (match != null) {
      final int h = int.parse(match.group(1)!);
      final int m = int.parse(match.group(2)!);
      if (h <= 23 && m <= 59) return TimeOfDay(hour: h, minute: m);
    }
    return TimeOfDay.now();
  }

  /// Selector de hora con ruedas (hoja inferior). A diferencia del dial
  /// circular de Material, no tiene anillos superpuestos en 24 h: una rueda de
  /// horas, otra de minutos y, en 12 h, una de AM/PM.
  Future<void> _seleccionar(BuildContext context) async {
    final TimeOfDay inicial = _inicial();
    final MaterialLocalizations textos = MaterialLocalizations.of(context);
    final ThemeData tema = Theme.of(context);

    DateTime seleccion = DateTime(2000, 1, 1, inicial.hour, inicial.minute);

    final bool? aceptado = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: tema.brightness,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 22,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: formato24h,
                    initialDateTime: seleccion,
                    onDateTimeChanged: (DateTime d) => seleccion = d,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(textos.cancelButtonLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(textos.okButtonLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (aceptado == true) {
      final String hh = seleccion.hour.toString().padLeft(2, '0');
      final String mm = seleccion.minute.toString().padLeft(2, '0');
      onChanged('$hh:$mm');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String texto = value.isEmpty
        ? ''
        : TimeFormatter.formatearHora(value, formato24h: formato24h);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _seleccionar(context),
      child: InputDecorator(
        isEmpty: value.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time),
          suffixIcon: value.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(''),
                ),
        ),
        child: Text(texto),
      ),
    );
  }
}