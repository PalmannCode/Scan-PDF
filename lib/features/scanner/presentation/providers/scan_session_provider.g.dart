// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScanSessionNotifier)
final scanSessionProvider = ScanSessionNotifierProvider._();

final class ScanSessionNotifierProvider
    extends $NotifierProvider<ScanSessionNotifier, ScanSession> {
  ScanSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanSessionNotifierHash();

  @$internal
  @override
  ScanSessionNotifier create() => ScanSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanSession>(value),
    );
  }
}

String _$scanSessionNotifierHash() =>
    r'fbf5316065451c8b3434030268714c680d0d9514';

abstract class _$ScanSessionNotifier extends $Notifier<ScanSession> {
  ScanSession build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ScanSession, ScanSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScanSession, ScanSession>,
              ScanSession,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
