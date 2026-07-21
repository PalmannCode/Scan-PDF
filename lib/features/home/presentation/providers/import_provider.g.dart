// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(importController)
final importControllerProvider = ImportControllerProvider._();

final class ImportControllerProvider
    extends
        $FunctionalProvider<
          ImportController,
          ImportController,
          ImportController
        >
    with $Provider<ImportController> {
  ImportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importControllerHash();

  @$internal
  @override
  $ProviderElement<ImportController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportController create(Ref ref) {
    return importController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportController>(value),
    );
  }
}

String _$importControllerHash() => r'0880e4883b1d5ba0f32f21daa9fd37da685d55b2';
