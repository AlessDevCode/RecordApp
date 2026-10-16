// lib/features/tasks/presentation/providers/clock_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emite la hora actual al comenzar cada minuto.
///
/// Las tarjetas y la lista filtrada lo observan para recalcular su estado con
/// el paso del tiempo sin que el usuario haga nada: por ejemplo, para que una
/// rutina deje de estar en CRÍTICO justo cuando termina su ventana de
/// tolerancia y muestre de inmediato la siguiente ocurrencia.
///
/// Se libera solo cuando ya nadie lo observa.
final StreamProvider<DateTime> clockProvider =
    StreamProvider.autoDispose<DateTime>((_) async* {
  yield DateTime.now();
  while (true) {
    final DateTime ahora = DateTime.now();
    final int msHastaProximoMinuto =
        60000 - (ahora.second * 1000 + ahora.millisecond);
    await Future<void>.delayed(
      Duration(milliseconds: msHastaProximoMinuto + 100),
    );
    yield DateTime.now();
  }
});