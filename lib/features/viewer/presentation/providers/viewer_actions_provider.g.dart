// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewer_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(signatureStore)
final signatureStoreProvider = SignatureStoreProvider._();

final class SignatureStoreProvider
    extends $FunctionalProvider<SignatureStore, SignatureStore, SignatureStore>
    with $Provider<SignatureStore> {
  SignatureStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signatureStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signatureStoreHash();

  @$internal
  @override
  $ProviderElement<SignatureStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignatureStore create(Ref ref) {
    return signatureStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignatureStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignatureStore>(value),
    );
  }
}

String _$signatureStoreHash() => r'2bf1e815eac3a5d1eaa8297648359927043663b9';

@ProviderFor(viewerActions)
final viewerActionsProvider = ViewerActionsProvider._();

final class ViewerActionsProvider
    extends $FunctionalProvider<ViewerActions, ViewerActions, ViewerActions>
    with $Provider<ViewerActions> {
  ViewerActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerActionsHash();

  @$internal
  @override
  $ProviderElement<ViewerActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ViewerActions create(Ref ref) {
    return viewerActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ViewerActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ViewerActions>(value),
    );
  }
}

String _$viewerActionsHash() => r'70013d662d65c69ef3ec34d8d8104d25f64cfc23';
