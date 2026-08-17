// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the app-lifetime purchase stream (keepAlive) so renewals and
/// restores are observed no matter which screen is open.

@ProviderFor(Plus)
final plusProvider = PlusProvider._();

/// Owns the app-lifetime purchase stream (keepAlive) so renewals and
/// restores are observed no matter which screen is open.
final class PlusProvider extends $NotifierProvider<Plus, PlusState> {
  /// Owns the app-lifetime purchase stream (keepAlive) so renewals and
  /// restores are observed no matter which screen is open.
  PlusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plusHash();

  @$internal
  @override
  Plus create() => Plus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlusState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlusState>(value),
    );
  }
}

String _$plusHash() => r'2e78f1ee3b67bb49ad575b0f83ea72974d5a1aa0';

/// Owns the app-lifetime purchase stream (keepAlive) so renewals and
/// restores are observed no matter which screen is open.

abstract class _$Plus extends $Notifier<PlusState> {
  PlusState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlusState, PlusState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlusState, PlusState>,
              PlusState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
