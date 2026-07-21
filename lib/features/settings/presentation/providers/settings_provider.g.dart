// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appStateRepository)
final appStateRepositoryProvider = AppStateRepositoryProvider._();

final class AppStateRepositoryProvider
    extends
        $FunctionalProvider<
          AppStateRepository,
          AppStateRepository,
          AppStateRepository
        >
    with $Provider<AppStateRepository> {
  AppStateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStateRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppStateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppStateRepository create(Ref ref) {
    return appStateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppStateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppStateRepository>(value),
    );
  }
}

String _$appStateRepositoryHash() =>
    r'ab32e6b3235e7fd64e0ce632f04dd80c6016fa59';

@ProviderFor(Settings)
final settingsProvider = SettingsProvider._();

final class SettingsProvider extends $NotifierProvider<Settings, ScanSettings> {
  SettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsHash();

  @$internal
  @override
  Settings create() => Settings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanSettings>(value),
    );
  }
}

String _$settingsHash() => r'81407dcc148bff982db4bbe00ef72828be4ac191';

abstract class _$Settings extends $Notifier<ScanSettings> {
  ScanSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ScanSettings, ScanSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScanSettings, ScanSettings>,
              ScanSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

final class ThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return themeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeHash() => r'0d60ff31337fe156ccbe3313b275df996362644f';
