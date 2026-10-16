// lib/features/tasks/presentation/widgets/multi_date_picker.dart
import 'package:flutter/material.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';

/// Abre un calendario donde se pueden marcar varias fechas (Flutter no trae un
/// selector múltiple). Devuelve las fechas elegidas (`YYYY-MM-DD`, ordenadas)
/// o null si se cancela. Las fechas pasadas no se pueden elegir.
///
/// [etiquetasDias]: 7 etiquetas cortas de lunes a domingo.
Future<List<String>?> mostrarSelectorFechasMultiples(
  BuildContext context, {
  required List<String> seleccionInicial,
  required List<String> etiquetasDias,
  required String titulo,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (BuildContext ctx) => _DialogoFechas(
      seleccionInicial: seleccionInicial,
      etiquetasDias: etiquetasDias,
      titulo: titulo,
    ),
  );
}

class _DialogoFechas extends StatefulWidget {
  const _DialogoFechas({
    required this.seleccionInicial,
    required this.etiquetasDias,
    required this.titulo,
  });

  final List<String> seleccionInicial;
  final List<String> etiquetasDias;
  final String titulo;

  @override
  State<_DialogoFechas> createState() => _DialogoFechasState();
}

class _DialogoFechasState extends State<_DialogoFechas> {
  late final Set<String> _seleccion = <String>{...widget.seleccionInicial};
  late final DateTime _hoy = _soloFecha(DateTime.now());
  late DateTime _mes = DateTime(_hoy.year, _hoy.month);

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _puedeRetroceder =>
      _mes.isAfter(DateTime(_hoy.year, _hoy.month));

  bool get _puedeAvanzar => _mes.isBefore(DateTime(_hoy.year + 3, _hoy.month));

  void _alternar(DateTime dia) {
    final String iso = TimeFormatter.fechaDb(dia);
    setState(() {
      if (!_seleccion.remove(iso)) _seleccion.add(iso);
    });
  }

  Widget _celda(int numeroDia, int diasDelMes, ThemeData tema) {
    if (numeroDia < 1 || numeroDia > diasDelMes) {
      return const SizedBox(height: 40);
    }
    final DateTime dia = DateTime(_mes.year, _mes.month, numeroDia);
    final String iso = TimeFormatter.fechaDb(dia);
    final bool pasada = dia.isBefore(_hoy);
    final bool elegida = _seleccion.contains(iso);
    final bool esHoy = dia == _hoy;
    final ColorScheme c = tema.colorScheme;

    return SizedBox(
      height: 40,
      child: Center(
        child: InkResponse(
          onTap: pasada ? null : () => _alternar(dia),
          radius: 20,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: elegida ? c.primary : null,
              border: esHoy && !elegida
                  ? Border.all(color: c.primary)
                  : null,
            ),
            child: Text(
              '$numeroDia',
              style: TextStyle(
                color: pasada
                    ? c.onSurface.withValues(alpha: 0.38)
                    : (elegida ? c.onPrimary : c.onSurface),
                fontWeight: elegida ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final MaterialLocalizations textos = MaterialLocalizations.of(context);

    // Lunes = 1. Celdas vacías antes del día 1 del mes.
    final int huecos = DateTime(_mes.year, _mes.month, 1).weekday - 1;
    final int diasDelMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final int filas = ((huecos + diasDelMes) / 7).ceil();

    return AlertDialog(
      title: Text('${widget.titulo} (${_seleccion.length})'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _puedeRetroceder
                        ? () => setState(
                              () => _mes = DateTime(_mes.year, _mes.month - 1),
                            )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      textos.formatMonthYear(_mes),
                      textAlign: TextAlign.center,
                      style: tema.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _puedeAvanzar
                        ? () => setState(
                              () => _mes = DateTime(_mes.year, _mes.month + 1),
                            )
                        : null,
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  for (final String etiqueta in widget.etiquetasDias)
                    Expanded(
                      child: Center(
                        child: Text(
                          etiqueta,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (int fila = 0; fila < filas; fila++)
                Row(
                  children: <Widget>[
                    for (int col = 0; col < 7; col++)
                      Expanded(
                        child: _celda(
                          fila * 7 + col - huecos + 1,
                          diasDelMes,
                          tema,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(textos.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _seleccion.toList()..sort(),
          ),
          child: Text(textos.okButtonLabel),
        ),
      ],
    );
  }
}