// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationService)
final notificationServiceProvider = NotificationServiceProvider._();

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          NotificationService,
          NotificationService,
          NotificationService
        >
    with $Provider<NotificationService> {
  NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'585c1e42ea844e71a2b76b80b165adfe2c5c8529';

/// Audios detectados dinámicamente en `assets/audio/`.

@ProviderFor(alertSounds)
final alertSoundsProvider = AlertSoundsProvider._();

/// Audios detectados dinámicamente en `assets/audio/`.

final class AlertSoundsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AlertSound>>,
          List<AlertSound>,
          FutureOr<List<AlertSound>>
        >
    with $FutureModifier<List<AlertSound>>, $FutureProvider<List<AlertSound>> {
  /// Audios detectados dinámicamente en `assets/audio/`.
  AlertSoundsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertSoundsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertSoundsHash();

  @$internal
  @override
  $FutureProviderElement<List<AlertSound>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AlertSound>> create(Ref ref) {
    return alertSounds(ref);
  }
}

String _$alertSoundsHash() => r'0b5584b4afdbbed8910e52ec7828110831de3310';

@ProviderFor(missionNotificationScheduler)
final missionNotificationSchedulerProvider =
    MissionNotificationSchedulerProvider._();

final class MissionNotificationSchedulerProvider
    extends
        $FunctionalProvider<
          MissionNotificationScheduler,
          MissionNotificationScheduler,
          MissionNotificationScheduler
        >
    with $Provider<MissionNotificationScheduler> {
  MissionNotificationSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missionNotificationSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missionNotificationSchedulerHash();

  @$internal
  @override
  $ProviderElement<MissionNotificationScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MissionNotificationScheduler create(Ref ref) {
    return missionNotificationScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissionNotificationScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissionNotificationScheduler>(value),
    );
  }
}

String _$missionNotificationSchedulerHash() =>
    r'89533f32bb827f1d57c2f5d329274d3a32915091';
