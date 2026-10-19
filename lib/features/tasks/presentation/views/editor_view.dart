// lib/features/tasks/presentation/views/editor_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recordapp/core/i18n/translation_extension.dart';
import 'package:recordapp/features/alarms/data/services/alert_audio_service.dart';
import 'package:recordapp/features/alarms/data/services/custom_sound_service.dart';
import 'package:recordapp/features/alarms/domain/models/alert_sound.dart';
import 'package:recordapp/features/alarms/presentation/providers/alarm_providers.dart';
import 'package:recordapp/features/alarms/presentation/providers/notification_providers.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/models/time_format_pref.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/tasks/domain/models/alarm_type.dart';
import 'package:recordapp/features/tasks/domain/models/repeat_type.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/domain/models/task_category.dart';
import 'package:recordapp/features/tasks/domain/services/routine_service.dart';
import 'package:recordapp/features/tasks/domain/services/smart_tagger.dart';
import 'package:recordapp/features/tasks/domain/services/time_formatter.dart';
import 'package:recordapp/features/tasks/presentation/providers/task_providers.dart';
import 'package:recordapp/features/tasks/presentation/widgets/custom_inputs.dart';
import 'package:recordapp/features/tasks/presentation/widgets/multi_date_picker.dart';

/// Crea una misión nueva o, si se pasa [task], edita esa misión.
class EditorView extends ConsumerStatefulWidget {
  const EditorView({this.task, super.key});

  final Task? task;

  @override
  ConsumerState<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends ConsumerState<EditorView> {
  final TextEditingController _tituloCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();

  late final AlertAudioService _audio;

  String _categoria = kCategoriaAutomatica;
  String _fecha = '';
  String _hora = '';
  AlarmType _alarma = AlarmType.sonido;

  /// Nombre de archivo elegido; vacío = el predeterminado del catálogo.
  String _sonido = '';
  bool _guardando = false;
  String? _errorTitulo;

  /// Audio propio elegido (URI de MediaStore); vacío = se usa uno de assets.
  String _sonidoUri = '';
  String _sonidoNombre = '';
  bool _importando = false;

  /// Cambia cuando se intenta elegir un archivo, para reconstruir el
  /// desplegable con la selección real (no con la opción "Elegir archivo").
  int _revSelector = 0;

  bool _duracionPersonalizada = false;
  /// Frecuencia de la misión y sus datos (solo se guardan los de la elegida).
  RepeatType _frecuencia = RepeatType.none;
  final Set<int> _diasSemana = <int>{}; // 1 = lunes … 7 = domingo
  List<String> _fechasEspeciales = <String>[]; // YYYY-MM-DD

  /// Bloques de horario secundarios (hora distinta para ciertos días/fechas).
  final List<_Bloque> _bloques = <_Bloque>[];

  final TextEditingController _minutosCtrl = TextEditingController();
  final TextEditingController _segundosCtrl = TextEditingController();

  static const String _opcionPropio = '__propio__';
  static const String _opcionElegir = '__elegir__';
  static const int _maxDuracionSeg = 1800; // 30 min

  /// Repetición automática de la alarma (sonido o vibración): desactivada por
  /// defecto. [_reintentos] son las veces que se repite tras la primera alerta.
  bool _repetir = false;
  int _reintentos = 3;
  int _intervaloMin = 5;
  static const List<int> _opcionesReintentos = <int>[2, 3, 5];
  static const List<int> _opcionesIntervalo = <int>[3, 5, 10, 15];

  bool get _editando => widget.task != null;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(alertAudioServiceProvider);

    final Task? t = widget.task;
    if (t != null) {
      _tituloCtrl.text = t.titulo;
      _descripcionCtrl.text = t.descripcion;
      _categoria = SmartTagger.categorias.any(
        (TaskCategory c) => c.nombre == t.categoriaId,
      )
          ? t.categoriaId
          : kCategoriaAutomatica;
      _fecha = t.fechaLimite;
      _hora = t.horaLimite;
      _alarma = t.tipoAlarma;
      _sonido = t.sonido;
      _frecuencia = t.repeatType;
      _diasSemana.addAll(t.repeatDays);
      _fechasEspeciales = <String>[...t.customDates];

      // repeatTimes (día/fecha → hora) se muestra como bloques, uno por hora.
      // Si había una hora principal (versiones anteriores) y quedan días o
      // fechas sin hora propia, pasan a un bloque con esa hora: así todo queda
      // cubierto por bloques y el campo de hora única no es necesario.
      if (t.repeatTimes.isNotEmpty) {
        final Map<String, Set<String>> porHora = <String, Set<String>>{};
        t.repeatTimes.forEach((String clave, String hora) {
          porHora.putIfAbsent(hora, () => <String>{}).add(clave);
        });
        final Set<String> todas = t.repeatType == RepeatType.weekly
            ? t.repeatDays.map((int d) => '$d').toSet()
            : t.customDates.toSet();
        final Set<String> sinHora =
            todas.difference(t.repeatTimes.keys.toSet());
        if (sinHora.isNotEmpty && RoutineService.horaValida(t.horaLimite)) {
          porHora
              .putIfAbsent(t.horaLimite.trim(), () => <String>{})
              .addAll(sinHora);
        }
        for (final String hora in porHora.keys.toList()..sort()) {
          _bloques.add(_Bloque(hora: hora)..claves.addAll(porHora[hora]!));
        }
      }
      _sonidoUri = t.sonidoUri;
      _sonidoNombre = t.sonidoNombre;
      if (t.repeatCount > 0 && t.intervalMinutes > 0) {
        _repetir = true;
        _reintentos = t.repeatCount;
        _intervaloMin = t.intervalMinutes;
      }
      if (t.duracionSeg > 0) {
        _duracionPersonalizada = true;
        _minutosCtrl.text = (t.duracionSeg ~/ 60).toString().padLeft(2, '0');
        _segundosCtrl.text = (t.duracionSeg % 60).toString().padLeft(2, '0');
      }
    }
  }

  @override
  void dispose() {
    unawaited(_audio.detener());
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _minutosCtrl.dispose();
    _segundosCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    final String titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      setState(() {
        _errorTitulo =
            ref.trOnce('editor.title_required', 'El título es obligatorio');
      });
      return;
    }

    // La duración personalizada solo cuenta si la alerta es un sonido.
    final TaskCategory detectada = SmartTagger.escanearCategoria(titulo);
    final String categoriaDestino =
        _categoria == kCategoriaAutomatica ? detectada.nombre : _categoria;
    final bool suena = categoriaDestino != 'NOTAS' &&
        (categoriaDestino == 'ALARMA' || _alarma == AlarmType.sonido);
    // La repetición automática aplica a sonido y vibración (no a silencioso).
    final bool conAlerta = categoriaDestino != 'NOTAS' &&
        (categoriaDestino == 'ALARMA' || _alarma != AlarmType.silencioso);
    final ({int segundos, String? error}) duracion = _evaluarDuracion(
      (String clave, String texto) => ref.trOnce(clave, texto),
    );
    final String? errorDuracion = duracion.error;
    if (suena && errorDuracion != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorDuracion)),
      );
      return;
    }

    // Rutinas: hace falta al menos un día o una fecha.
    final bool esNota = categoriaDestino == 'NOTAS';
    String? errorRutina;
    if (!esNota &&
        _frecuencia == RepeatType.weekly &&
        _diasSemana.isEmpty) {
      errorRutina = ref.trOnce(
        'editor.repeat_pick_days',
        'Marca al menos un día de la semana',
      );
    } else if (!esNota &&
        _frecuencia == RepeatType.customDates &&
        _fechasEspeciales.isEmpty) {
      errorRutina = ref.trOnce(
        'editor.repeat_pick_dates',
        'Elige al menos una fecha',
      );
    }
    if (errorRutina == null && !esNota && _usaBloques) {
      if (_hayBloqueSinHora()) {
        errorRutina = ref.trOnce(
          'editor.block_pick_time',
          'Elige la hora de cada bloque de horario',
        );
      } else if (_hayClavesSinBloque()) {
        errorRutina = ref.trOnce(
          'editor.block_assign_all',
          'Asigna cada día o fecha a un bloque de horario',
        );
      }
    }
    if (errorRutina != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorRutina)),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final List<AlertSound> sonidos =
          ref.read(alertSoundsProvider).value ?? const <AlertSound>[];
      final AlertSound? efectivo = resolverSonido(sonidos, _sonido);

      final TaskCategory automatica = SmartTagger.escanearCategoria(titulo);
      final bool guardada =
          await ref.read(taskListProvider.notifier).guardarTarea(
                titulo: titulo,
                descripcion: _descripcionCtrl.text,
                categoriaSeleccionada: _categoria,
                categoriaActualAutomatica: automatica.nombre,
                fecha: _fecha,
                hora: _usaBloques ? '' : _hora,
                tipoAlarma: _alarma,
                sonido: efectivo?.fileName ?? _sonido,
                sonidoUri: _sonidoUri,
                sonidoNombre: _sonidoNombre,
                duracionSeg: suena ? duracion.segundos : 0,
                repeatCount: conAlerta && _repetir ? _reintentos : 0,
                intervalMinutes: conAlerta && _repetir ? _intervaloMin : 0,
                repeatType: _frecuencia,
                repeatTimes: _construirHorarios(),
                repeatDays: _diasSemana,
                customDates: _fechasEspeciales,
                existente: widget.task,
              );

      if (!mounted) return;
      if (guardada) {
        context.pop();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.trOnce('editor.save_error', 'No se pudo guardar la misión'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _previsualizar(AlertSound? sonido) async {
    if (sonido == null) return;
    try {
      await _audio.reproducir(sonido);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.trOnce('editor.sound_error', 'No se pudo reproducir el sonido'),
          ),
        ),
      );
    }
  }

  /// 7 etiquetas de lunes a domingo (traducibles: "L,M,M,J,V,S,D").
  List<String> _etiquetasDias() {
    final List<String> etiquetas = ref
        .tr('editor.weekdays_short', RoutineService.etiquetasDiasPorDefecto)
        .split(',');
    return etiquetas.length == 7
        ? etiquetas
        : RoutineService.etiquetasDiasPorDefecto.split(',');
  }

  // ---------- Bloques de horario por día / fecha ----------

  /// Claves seleccionadas hoy: días de la semana ("1".."7") o fechas ISO.
  Set<String> _clavesDisponibles() {
    switch (_frecuencia) {
      case RepeatType.weekly:
        return _diasSemana.map((int d) => '$d').toSet();
      case RepeatType.customDates:
        return _fechasEspeciales.toSet();
      case RepeatType.none:
        return <String>{};
    }
  }

  /// Claves disponibles ordenadas (lunes → domingo, o por fecha).
  List<String> _clavesOrdenadas() {
    final List<String> claves = _clavesDisponibles().toList();
    if (_frecuencia == RepeatType.weekly) {
      claves.sort((String a, String b) => int.parse(a).compareTo(int.parse(b)));
    } else {
      claves.sort();
    }
    return claves;
  }

  /// Quita de los bloques los días o fechas que ya no están seleccionados.
  void _podarBloques() {
    final Set<String> disponibles = _clavesDisponibles();
    for (final _Bloque b in _bloques) {
      b.claves.retainAll(disponibles);
    }
  }

  /// Un día o fecha pertenece como máximo a un bloque: al asignarlo a [b] se
  /// retira de los demás.
  void _asignarAlBloque(_Bloque b, String clave, {required bool asignar}) {
    if (asignar) {
      for (final _Bloque otro in _bloques) {
        if (!identical(otro, b)) otro.claves.remove(clave);
      }
      b.claves.add(clave);
    } else {
      b.claves.remove(clave);
    }
  }

  /// Mapa día/fecha → hora para guardar en la tarea.
  Map<String, String> _construirHorarios() {
    final Set<String> disponibles = _clavesDisponibles();
    final Map<String, String> horarios = <String, String>{};
    for (final _Bloque b in _bloques) {
      if (!RoutineService.horaValida(b.hora)) continue;
      for (final String clave in b.claves) {
        if (disponibles.contains(clave)) horarios[clave] = b.hora;
      }
    }
    return horarios;
  }

  /// true cuando la rutina usa bloques de horario: entonces el campo de hora
  /// única desaparece y cada día o fecha depende de su bloque.
  bool get _usaBloques =>
      _frecuencia != RepeatType.none && _bloques.isNotEmpty;

  /// ¿Queda algún día o fecha seleccionado que no está en ningún bloque?
  bool _hayClavesSinBloque() {
    final Set<String> cubiertas = <String>{
      for (final _Bloque b in _bloques)
        if (RoutineService.horaValida(b.hora)) ...b.claves,
    };
    return !cubiertas.containsAll(_clavesDisponibles());
  }

  /// Agrega un bloque. El primero parte de la hora que ya estaba elegida y de
  /// todos los días/fechas; los siguientes, de los que aún no tienen bloque.
  void _agregarBloque() {
    final Set<String> disponibles = _clavesDisponibles();
    final bool primero = _bloques.isEmpty;
    final Set<String> asignadas = <String>{
      for (final _Bloque b in _bloques) ...b.claves,
    };
    final _Bloque nuevo = _Bloque(hora: primero ? _hora : '')
      ..claves.addAll(primero ? disponibles : disponibles.difference(asignadas));
    _bloques.add(nuevo);
  }

  /// ¿Hay algún bloque con días asignados pero sin hora?
  bool _hayBloqueSinHora() {
    final Set<String> disponibles = _clavesDisponibles();
    return _bloques.any(
      (_Bloque b) =>
          !RoutineService.horaValida(b.hora) &&
          b.claves.any(disponibles.contains),
    );
  }

  String _etiquetaClave(String clave, AppSettings settings) {
    if (_frecuencia == RepeatType.weekly) {
      final List<String> nombres = ref
          .tr('editor.weekdays_medium', 'Lun,Mar,Mié,Jue,Vie,Sáb,Dom')
          .split(',');
      final int? dia = int.tryParse(clave);
      if (dia != null && dia >= 1 && dia <= nombres.length) {
        return nombres[dia - 1];
      }
      return clave;
    }
    return TimeFormatter.formatearFecha(clave, patron: settings.dateFormat);
  }

  Widget _tarjetaBloque(
    ThemeData theme,
    AppSettings settings,
    _Bloque bloque,
    List<String> claves,
  ) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TimePickerField(
                    label: ref.tr('editor.block_time', 'Hora de este bloque'),
                    value: bloque.hora,
                    formato24h: settings.timeFormat == TimeFormatPref.h24,
                    onChanged: (String v) => setState(() => bloque.hora = v),
                  ),
                ),
                IconButton(
                  tooltip: ref.tr('editor.block_remove', 'Quitar bloque'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                    _bloques.remove(bloque);
                    // Al quitar el último bloque vuelve el campo de hora única,
                    // conservando la hora que tenía ese bloque.
                    if (_bloques.isEmpty &&
                        RoutineService.horaValida(bloque.hora)) {
                      _hora = bloque.hora;
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  for (final String clave in claves)
                    FilterChip(
                      label: Text(_etiquetaClave(clave, settings)),
                      selected: bloque.claves.contains(clave),
                      onSelected: (bool valor) => setState(
                        () => _asignarAlBloque(bloque, clave, asignar: valor),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Horarios por día": la hora principal es la del campo "Hora principal";
  /// aquí se agregan bloques para dar otra hora a días o fechas concretos.
  Widget _seccionBloques(ThemeData theme, AppSettings settings) {
    final TextStyle? estiloInfo = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final List<String> claves = _clavesOrdenadas();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ref.tr('editor.blocks', 'Horarios por día'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: Icons.schedule,
          texto: _bloques.isEmpty
              ? ref.tr(
                  'editor.blocks_info_empty',
                  'Se usa la hora de arriba para todos los días. Agrega bloques '
                      'si quieres una hora distinta según el día.',
                )
              : ref.tr(
                  'editor.blocks_info',
                  'Cada día o fecha debe estar en un bloque, y solo en uno.',
                ),
          estilo: estiloInfo,
        ),
        for (final _Bloque b in _bloques)
          _tarjetaBloque(theme, settings, b, claves),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: claves.isEmpty ? null : () => setState(_agregarBloque),
            icon: const Icon(Icons.add),
            label: Text(
              ref.tr('editor.block_add', 'Agregar bloque de horario'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _elegirFechas() async {
    final List<String>? elegidas = await mostrarSelectorFechasMultiples(
      context,
      seleccionInicial: _fechasEspeciales,
      etiquetasDias: _etiquetasDias(),
      titulo: ref.tr('editor.special_dates', 'Fechas especiales'),
    );
    if (!mounted || elegidas == null) return;
    setState(() {
      _fechasEspeciales = elegidas;
      _podarBloques();
    });
  }

  /// Desplegable "Frecuencia" y, según la opción, los días de la semana o el
  /// botón del calendario de fechas especiales.
  Widget _seccionFrecuencia(ThemeData theme, AppSettings settings) {
    final TextStyle? estiloInfo = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final List<String> dias = _etiquetasDias();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<RepeatType>(
          initialValue: _frecuencia,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: ref.tr('editor.frequency', 'Frecuencia'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.repeat),
          ),
          items: <DropdownMenuItem<RepeatType>>[
            DropdownMenuItem<RepeatType>(
              value: RepeatType.none,
              child: Text(ref.tr('editor.frequency_once', 'Una sola vez')),
            ),
            DropdownMenuItem<RepeatType>(
              value: RepeatType.weekly,
              child: Text(ref.tr('editor.frequency_weekly', 'Semanal')),
            ),
            DropdownMenuItem<RepeatType>(
              value: RepeatType.customDates,
              child: Text(ref.tr('editor.frequency_special', 'Especial')),
            ),
          ],
          onChanged: (RepeatType? valor) {
            if (valor == null) return;
            setState(() {
              _frecuencia = valor;
              _bloques.clear(); // Las claves de cada tipo no son compatibles.
            });
          },
        ),
        if (_frecuencia == RepeatType.weekly) ...<Widget>[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (int d = 1; d <= 7; d++)
                _DiaCirculo(
                  etiqueta: dias[d - 1],
                  seleccionado: _diasSemana.contains(d),
                  onTap: () => setState(() {
                    if (!_diasSemana.remove(d)) _diasSemana.add(d);
                    _podarBloques();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.info_outline,
            texto: _diasSemana.isEmpty
                ? ref.tr(
                    'editor.repeat_pick_days',
                    'Marca al menos un día de la semana',
                  )
                : ref.tr(
                    'editor.repeat_weekly_info',
                    'Se repite esos días a la hora límite. Al marcarla como '
                        'hecha, se programa el siguiente día que toque.',
                  ),
            estilo: _diasSemana.isEmpty
                ? estiloInfo?.copyWith(color: theme.colorScheme.error)
                : estiloInfo,
          ),
        ],
        if (_frecuencia == RepeatType.customDates) ...<Widget>[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _elegirFechas,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _fechasEspeciales.isEmpty
                    ? ref.tr('editor.special_pick', 'Elegir fechas')
                    : '${ref.tr('editor.special_edit', 'Editar fechas')} '
                        '(${_fechasEspeciales.length})',
              ),
            ),
          ),
          if (_fechasEspeciales.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final String fecha in _fechasEspeciales)
                  InputChip(
                    label: Text(
                      TimeFormatter.formatearFecha(
                        fecha,
                        patron: settings.dateFormat,
                      ),
                    ),
                    onDeleted: () => setState(() {
                      _fechasEspeciales = <String>[
                        for (final String f in _fechasEspeciales)
                          if (f != fecha) f,
                      ];
                      _podarBloques();
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.info_outline,
            texto: _fechasEspeciales.isEmpty
                ? ref.tr('editor.repeat_pick_dates', 'Elige al menos una fecha')
                : ref.tr(
                    'editor.repeat_special_info',
                    'Solo suena en esas fechas, a la hora límite. Al marcar la '
                        'última como hecha, la misión se archiva.',
                  ),
            estilo: _fechasEspeciales.isEmpty
                ? estiloInfo?.copyWith(color: theme.colorScheme.error)
                : estiloInfo,
          ),
        ],
      ],
    );
  }

  /// Abre el selector de archivos de Android y deja el audio elegido como
  /// sonido de esta misión.
  Future<void> _elegirArchivo() async {
    if (_importando) return;
    setState(() => _importando = true);
    try {
      final CustomSound? elegido = await const CustomSoundService().elegir();
      if (!mounted) return;
      if (elegido != null) {
        setState(() {
          _sonidoUri = elegido.uri;
          _sonidoNombre = elegido.nombre;
        });
      }
    } on CustomSoundException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importando = false;
          _revSelector++;
        });
      }
    }
  }

  /// Duración total = (minutos × 60) + segundos. Un campo vacío cuenta como 0.
  ///
  /// Devuelve los segundos totales (0 si es "Por defecto" o si hay error) y,
  /// si el valor no es válido, el mensaje que debe ver el usuario. [t] traduce
  /// el texto (`ref.tr` en `build`, `ref.trOnce` al guardar).
  ({int segundos, String? error}) _evaluarDuracion(
    String Function(String clave, String texto) t,
  ) {
    if (!_duracionPersonalizada) return (segundos: 0, error: null);

    final int minutos = int.tryParse(_minutosCtrl.text.trim()) ?? 0;
    final int segundos = int.tryParse(_segundosCtrl.text.trim()) ?? 0;

    if (segundos > 59) {
      return (
        segundos: 0,
        error: t('editor.duration_seconds_range', 'Los segundos van de 0 a 59'),
      );
    }

    final int total = minutos * 60 + segundos;
    if (total < 1) {
      return (
        segundos: 0,
        error: t(
          'editor.duration_min',
          'La duración debe ser de al menos 1 segundo',
        ),
      );
    }
    if (total > _maxDuracionSeg) {
      return (
        segundos: 0,
        error: t('editor.duration_max', 'El máximo es 30 minutos (30:00)'),
      );
    }
    return (segundos: total, error: null);
  }

  /// `90` → `01:30`.
  String _formatoMmSs(int total) {
    final String mm = (total ~/ 60).toString().padLeft(2, '0');
    final String ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Widget _campoTiempo({
    required TextEditingController controller,
    required String etiqueta,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// "Repetir alarma automáticamente": desactivada por defecto. Al activarla se
  /// despliega un recuadro compacto con el número de repeticiones y el
  /// intervalo en minutos. Con la opción apagada solo ocupa una fila.
  Widget _seccionRepeticion(ThemeData theme) {
    final TextStyle? estiloInfo = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // Se conserva un valor guardado aunque no esté entre las opciones.
    final List<int> opcionesRep = <int>{..._opcionesReintentos, _reintentos}
        .toList()
      ..sort();
    final List<int> opcionesInt = <int>{..._opcionesIntervalo, _intervaloMin}
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.replay),
          title: Text(
            ref.tr('editor.auto_repeat', 'Repetir alarma automáticamente'),
          ),
          value: _repetir,
          onChanged: (bool valor) => setState(() => _repetir = valor),
        ),
        if (_repetir)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _reintentos,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: ref.tr('editor.repeat_times', 'Repeticiones'),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<int>>[
                          for (final int n in opcionesRep)
                            DropdownMenuItem<int>(
                              value: n,
                              child: Text(
                                '$n ${ref.tr('editor.repeat_times_unit', 'veces')}',
                              ),
                            ),
                        ],
                        onChanged: (int? valor) {
                          if (valor != null) setState(() => _reintentos = valor);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _intervaloMin,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: ref.tr('editor.repeat_interval', 'Cada'),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<int>>[
                          for (final int n in opcionesInt)
                            DropdownMenuItem<int>(
                              value: n,
                              child: Text('$n min'),
                            ),
                        ],
                        onChanged: (int? valor) {
                          if (valor != null) setState(() => _intervaloMin = valor);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.info_outline,
                  texto: ref
                      .tr(
                        'editor.auto_repeat_info',
                        'Tras la primera alerta se repetirá {n} veces, cada '
                            '{m} min. Se detiene al completar la misión.',
                      )
                      .replaceAll('{n}', '$_reintentos')
                      .replaceAll('{m}', '$_intervaloMin'),
                  estilo: estiloInfo,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _seccionDuracion(ThemeData theme) {
    final TextStyle? estiloInfo = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final ({int segundos, String? error}) duracion = _evaluarDuracion(
      (String clave, String texto) => ref.tr(clave, texto),
    );
    final String? error = duracion.error;
    final String etiquetaTotal = ref.tr('editor.duration_total', 'Total');
    final String ayudaPersonalizada = ref.tr(
      'editor.duration_custom_info',
      'se repite hasta completar ese tiempo (máx. 30:00). La notificación '
          'se retira sola al terminar.',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ref.tr('editor.duration', 'Duración del sonido'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: false,
                label: _EtiquetaSegmento(
                  ref.tr('editor.duration_default', 'Por defecto'),
                ),
              ),
              ButtonSegment<bool>(
                value: true,
                label: _EtiquetaSegmento(
                  ref.tr('editor.duration_custom', 'Personalizado'),
                ),
              ),
            ],
            selected: <bool>{_duracionPersonalizada},
            onSelectionChanged: (Set<bool> seleccion) {
              setState(() {
                _duracionPersonalizada = seleccion.first;
                // Valor inicial cómodo: 00:30.
                if (_duracionPersonalizada &&
                    _minutosCtrl.text.isEmpty &&
                    _segundosCtrl.text.isEmpty) {
                  _minutosCtrl.text = '00';
                  _segundosCtrl.text = '30';
                }
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        if (!_duracionPersonalizada)
          _InfoRow(
            icon: Icons.music_note_outlined,
            texto: ref.tr(
              'editor.duration_default_info',
              'El sonido se reproduce una vez, con la duración del propio audio.',
            ),
            estilo: estiloInfo,
          )
        else ...<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _campoTiempo(
                  controller: _minutosCtrl,
                  etiqueta: ref.tr('editor.minutes', 'Minutos'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(':', style: theme.textTheme.headlineSmall),
              ),
              Expanded(
                child: _campoTiempo(
                  controller: _segundosCtrl,
                  etiqueta: ref.tr('editor.seconds', 'Segundos'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (error != null)
            _InfoRow(
              icon: Icons.error_outline,
              texto: error,
              estilo: estiloInfo?.copyWith(color: theme.colorScheme.error),
            )
          else
            _InfoRow(
              icon: Icons.repeat,
              texto: '$etiquetaTotal: ${_formatoMmSs(duracion.segundos)} · '
                  '$ayudaPersonalizada',
              estilo: estiloInfo,
            ),
        ],
      ],
    );
  }

  /// Bloque que cambia según el modo de alerta elegido.
  Widget _detalleDeAlarma(ThemeData theme, AlarmType modo) {
    final TextStyle? estiloInfo = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    switch (modo) {
      case AlarmType.silencioso:
        return _InfoRow(
          icon: Icons.notifications_none_outlined,
          texto: ref.tr(
            'editor.alarm_silent_info',
            'Se avisará mediante notificación al finalizar el plazo de la misión',
          ),
          estilo: estiloInfo,
        );
      case AlarmType.vibracion:
        return _InfoRow(
          icon: Icons.vibration,
          texto: ref.tr(
            'editor.alarm_vibration_info',
            'El dispositivo vibrará durante 3 segundos al culminar la misión',
          ),
          estilo: estiloInfo,
        );
      case AlarmType.sonido:
        final AsyncValue<List<AlertSound>> sonidosAsync =
            ref.watch(alertSoundsProvider);
        return sonidosAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (Object e, StackTrace s) => _InfoRow(
            icon: Icons.error_outline,
            texto: ref.tr(
              'editor.sounds_error',
              'No se pudieron leer los sonidos disponibles',
            ),
            estilo: estiloInfo,
          ),
          data: (List<AlertSound> sonidos) {
            final bool hayPropio = _sonidoUri.isNotEmpty;
            final AlertSound? seleccionado =
                hayPropio ? null : resolverSonido(sonidos, _sonido);
            final String? valor =
                hayPropio ? _opcionPropio : seleccionado?.fileName;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey<String>('sonido_${valor}_$_revSelector'),
                        initialValue: valor,
                        isExpanded: true,
                        hint: Text(
                          ref.tr(
                            'editor.sound_system_default',
                            'Sonido predeterminado del sistema',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        decoration: InputDecoration(
                          labelText: ref.tr('editor.sound', 'Sonido de alerta'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.music_note_outlined),
                        ),
                        items: <DropdownMenuItem<String>>[
                          for (final AlertSound s in sonidos)
                            DropdownMenuItem<String>(
                              value: s.fileName,
                              child: Text(
                                s.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (hayPropio)
                            DropdownMenuItem<String>(
                              value: _opcionPropio,
                              child: Text(
                                '🎵 $_sonidoNombre',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          DropdownMenuItem<String>(
                            value: _opcionElegir,
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.folder_open_outlined, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    ref.tr(
                                      'editor.sound_pick_file',
                                      'Elegir archivo de audio…',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? elegido) {
                          if (elegido == null) return;
                          if (elegido == _opcionElegir) {
                            unawaited(_elegirArchivo());
                            return;
                          }
                          if (elegido == _opcionPropio) return;
                          setState(() {
                            _sonido = elegido;
                            _sonidoUri = '';
                            _sonidoNombre = '';
                          });
                          unawaited(
                            _previsualizar(resolverSonido(sonidos, elegido)),
                          );
                        },
                      ),
                    ),
                    if (seleccionado != null) ...<Widget>[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: IconButton.filledTonal(
                          tooltip: ref.tr('editor.sound_preview', 'Escuchar'),
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () =>
                              unawaited(_previsualizar(seleccionado)),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_importando)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    ref.tr(
                      'editor.sound_custom_hint',
                      'Puedes usar un audio de tu teléfono (Android 10 o superior).',
                    ),
                    style: estiloInfo,
                  ),
                ),
              ],
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSettings settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();

    final TaskCategory automatica =
        ref.watch(autodetectedCategoryProvider(_tituloCtrl.text));
    final bool esAutomatica = _categoria == kCategoriaAutomatica;
    final String categoriaFinal = esAutomatica ? automatica.nombre : _categoria;
    final bool esNotas = categoriaFinal == 'NOTAS';
    final bool esAlarma = categoriaFinal == 'ALARMA';
    final AlarmType modoEfectivo = esAlarma ? AlarmType.sonido : _alarma;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando
              ? ref.tr('editor.title_edit', 'EDITAR MISIÓN')
              : ref.tr('editor.title', 'NUEVA MISIÓN'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: ref.tr('editor.field_title', 'Título'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.flag_outlined),
                errorText: _errorTitulo,
              ),
              onChanged: (_) => setState(() => _errorTitulo = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionCtrl,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: ref.tr('editor.field_description', 'Descripción'),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: InputDecoration(
                labelText: ref.tr('editor.category', 'Categoría'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: kCategoriaAutomatica,
                  child: Text(
                    '✨ ${ref.tr('editor.category_auto', 'AUTOMÁTICO')}',
                  ),
                ),
                for (final TaskCategory categoria in SmartTagger.categorias)
                  DropdownMenuItem<String>(
                    value: categoria.nombre,
                    child: Text(
                      '${categoria.emoji} ${ref.trCategoria(categoria.nombre)}',
                    ),
                  ),
              ],
              onChanged: (String? valor) {
                if (valor == null) return;
                setState(() => _categoria = valor);
              },
            ),
            if (esAutomatica)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ref.tr('editor.detected', 'Categoría detectada')}: '
                      '${automatica.emoji} ${ref.trCategoria(automatica.nombre)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (esNotas)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.notes_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ref.tr(
                            'editor.notes_hint',
                            'Las notas no manejan fecha, hora ni alarma.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...<Widget>[
              // Con bloques de horario, el campo de hora única desaparece: la
              // hora de cada día o fecha depende solo de su bloque.
              if (!_usaBloques) ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Una rutina no tiene una fecha única: sus días o fechas se
                      // eligen más abajo, y la hora límite vale para cada día.
                      if (_frecuencia == RepeatType.none) ...<Widget>[
                        Expanded(
                          child: DatePickerField(
                            label: ref.tr('editor.date', 'Fecha límite'),
                            value: _fecha,
                            displayPattern: settings.dateFormat,
                            onChanged: (String v) => setState(() => _fecha = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: TimePickerField(
                          label: ref.tr('editor.time', 'Hora límite'),
                          value: _hora,
                          formato24h: settings.timeFormat == TimeFormatPref.h24,
                          onChanged: (String v) => setState(() => _hora = v),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
              _seccionFrecuencia(theme, settings),
              if (_frecuencia != RepeatType.none) ...<Widget>[
                const SizedBox(height: 16),
                _seccionBloques(theme, settings),
              ],
              const SizedBox(height: 16),
              Text(
                ref.tr('editor.alarm', 'Tipo de alarma'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<AlarmType>(
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  segments: <ButtonSegment<AlarmType>>[
                    ButtonSegment<AlarmType>(
                      value: AlarmType.silencioso,
                      icon: const Icon(Icons.volume_off_outlined),
                      label: _EtiquetaSegmento(
                        ref.tr('editor.alarm_silent', 'Silencioso'),
                      ),
                    ),
                    ButtonSegment<AlarmType>(
                      value: AlarmType.sonido,
                      icon: const Icon(Icons.volume_up_outlined),
                      label: _EtiquetaSegmento(
                        ref.tr('editor.alarm_sound', 'Sonido'),
                      ),
                    ),
                    ButtonSegment<AlarmType>(
                      value: AlarmType.vibracion,
                      icon: const Icon(Icons.vibration),
                      label: _EtiquetaSegmento(
                        ref.tr('editor.alarm_vibration', 'Vibración'),
                      ),
                    ),
                  ],
                  selected: <AlarmType>{modoEfectivo},
                  onSelectionChanged: esAlarma
                      ? null
                      : (Set<AlarmType> seleccion) {
                          unawaited(_audio.detener());
                          setState(() => _alarma = seleccion.first);
                        },
                ),
              ),
              if (esAlarma)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    ref
                        .tr(
                          'editor.alarm_forced',
                          'La categoría {category} siempre usa sonido.',
                        )
                        .replaceAll('{category}', ref.trCategoria('ALARMA')),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _detalleDeAlarma(theme, modoEfectivo),
              if (modoEfectivo == AlarmType.sonido) ...<Widget>[
                const SizedBox(height: 16),
                _seccionDuracion(theme),
              ],
              // Repetición automática: sonido y vibración.
              if (modoEfectivo == AlarmType.sonido ||
                  modoEfectivo == AlarmType.vibracion) ...<Widget>[
                const SizedBox(height: 8),
                _seccionRepeticion(theme),
              ],
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(ref.tr('editor.save', 'Guardar misión')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtiquetaSegmento extends StatelessWidget {
  const _EtiquetaSegmento(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(texto, maxLines: 1, softWrap: false, overflow: TextOverflow.fade);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.texto,
    required this.estilo,
  });

  final IconData icon;
  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: estilo?.color),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: estilo)),
        ],
      ),
    );
  }
}

/// Botón circular de un día de la semana (L, M, M, J, V, S, D).
class _DiaCirculo extends StatelessWidget {
  const _DiaCirculo({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: seleccionado,
      label: etiqueta,
      child: Material(
        color: seleccionado ? c.primary : c.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: Text(
                etiqueta,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: seleccionado ? c.onPrimary : c.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloque de horario secundario del editor: una hora y los días o fechas a
/// los que se aplica (claves: "1".."7" en semanal, `YYYY-MM-DD` en especial).
class _Bloque {
  _Bloque({this.hora = ''});

  String hora;
  final Set<String> claves = <String>{};
}