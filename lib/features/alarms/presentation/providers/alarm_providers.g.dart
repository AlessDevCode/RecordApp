// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reproductor para escuchar los sonidos en el editor. La alerta real de una
/// misión no pasa por aquí: la entrega siempre la notificación del sistema.

@ProviderFor(alertAudioService)
final alertAudioServiceProvider = AlertAudioServiceProvider._();

/// Reproductor para escuchar los sonidos en el editor. La alerta real de una
/// misión no pasa por aquí: la entrega siempre la notificación del sistema.

final class AlertAudioServiceProvider
    extends
        $FunctionalProvider<
          AlertAudioService,
          AlertAudioService,
          AlertAudioService
        >
    with $Provider<AlertAudioService> {
  /// Reproductor para escuchar los sonidos en el editor. La alerta real de una
  /// misión no pasa por aquí: la entrega siempre la notificación del sistema.
  AlertAudioServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertAudioServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertAudioServiceHash();

  @$internal
  @override
  $ProviderElement<AlertAudioService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AlertAudioService create(Ref ref) {
    return alertAudioService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertAudioService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertAudioService>(value),
    );
  }
}

String _$alertAudioServiceHash() => r'fc239c0abe8277972ad6596fe3b138111054584c';
