// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsLocalDatasource)
final settingsLocalDatasourceProvider = SettingsLocalDatasourceProvider._();

final class SettingsLocalDatasourceProvider
    extends
        $FunctionalProvider<
          SettingsLocalDatasource,
          SettingsLocalDatasource,
          SettingsLocalDatasource
        >
    with $Provider<SettingsLocalDatasource> {
  SettingsLocalDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsLocalDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsLocalDatasourceHash();

  @$internal
  @override
  $ProviderElement<SettingsLocalDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsLocalDatasource create(Ref ref) {
    return settingsLocalDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsLocalDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsLocalDatasource>(value),
    );
  }
}

String _$settingsLocalDatasourceHash() =>
    r'0742e4b741d8153df2e9a6c9f3aea198eaeed798';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'07842f8e2c4fbd16e3ad8527c40f650ee65591d1';

@ProviderFor(localeAssetDatasource)
final localeAssetDatasourceProvider = LocaleAssetDatasourceProvider._();

final class LocaleAssetDatasourceProvider
    extends
        $FunctionalProvider<
          LocaleAssetDatasource,
          LocaleAssetDatasource,
          LocaleAssetDatasource
        >
    with $Provider<LocaleAssetDatasource> {
  LocaleAssetDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeAssetDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeAssetDatasourceHash();

  @$internal
  @override
  $ProviderElement<LocaleAssetDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocaleAssetDatasource create(Ref ref) {
    return localeAssetDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleAssetDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleAssetDatasource>(value),
    );
  }
}

String _$localeAssetDatasourceHash() =>
    r'7130be74b50a62b9415328e6c280bedfbe5e09cd';

/// Gestiona y persiste en SQLite toda la configuración, incluido el tema.

@ProviderFor(AppSettingsNotifier)
final appSettingsProvider = AppSettingsNotifierProvider._();

/// Gestiona y persiste en SQLite toda la configuración, incluido el tema.
final class AppSettingsNotifierProvider
    extends $AsyncNotifierProvider<AppSettingsNotifier, AppSettings> {
  /// Gestiona y persiste en SQLite toda la configuración, incluido el tema.
  AppSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsNotifierHash();

  @$internal
  @override
  AppSettingsNotifier create() => AppSettingsNotifier();
}

String _$appSettingsNotifierHash() =>
    r'eb386ed41ff746773efc51fef7a65d9c5506e661';

/// Gestiona y persiste en SQLite toda la configuración, incluido el tema.

abstract class _$AppSettingsNotifier extends $AsyncNotifier<AppSettings> {
  FutureOr<AppSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppSettings>, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppSettings>, AppSettings>,
              AsyncValue<AppSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// ThemeMode listo para `MaterialApp.themeMode`.
/// Solo notifica a sus dependientes cuando el modo cambia realmente.

@ProviderFor(appThemeMode)
final appThemeModeProvider = AppThemeModeProvider._();

/// ThemeMode listo para `MaterialApp.themeMode`.
/// Solo notifica a sus dependientes cuando el modo cambia realmente.

final class AppThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  /// ThemeMode listo para `MaterialApp.themeMode`.
  /// Solo notifica a sus dependientes cuando el modo cambia realmente.
  AppThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return appThemeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appThemeModeHash() => r'eb264f45d8d97a5a99bbd042e310f494dfa2587a';

/// Idioma activo. Solo notifica cuando el código de idioma cambia.

@ProviderFor(appLanguage)
final appLanguageProvider = AppLanguageProvider._();

/// Idioma activo. Solo notifica cuando el código de idioma cambia.

final class AppLanguageProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Idioma activo. Solo notifica cuando el código de idioma cambia.
  AppLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLanguageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLanguageHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appLanguage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appLanguageHash() => r'4f8b520edff8949d671d4db5f63f3737f7bccbb1';

/// Traductor reactivo: se reconstruye únicamente al cambiar el idioma.

@ProviderFor(translator)
final translatorProvider = TranslatorProvider._();

/// Traductor reactivo: se reconstruye únicamente al cambiar el idioma.

final class TranslatorProvider
    extends
        $FunctionalProvider<
          AsyncValue<Translator>,
          Translator,
          FutureOr<Translator>
        >
    with $FutureModifier<Translator>, $FutureProvider<Translator> {
  /// Traductor reactivo: se reconstruye únicamente al cambiar el idioma.
  TranslatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translatorHash();

  @$internal
  @override
  $FutureProviderElement<Translator> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Translator> create(Ref ref) {
    return translator(ref);
  }
}

String _$translatorHash() => r'b679dc6b60d0b5ad9c1400c7afe75b0792c995de';
