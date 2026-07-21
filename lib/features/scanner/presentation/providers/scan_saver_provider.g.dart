// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_saver_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scanSaver)
final scanSaverProvider = ScanSaverProvider._();

final class ScanSaverProvider
    extends $FunctionalProvider<ScanSaver, ScanSaver, ScanSaver>
    with $Provider<ScanSaver> {
  ScanSaverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanSaverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanSaverHash();

  @$internal
  @override
  $ProviderElement<ScanSaver> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScanSaver create(Ref ref) {
    return scanSaver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanSaver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanSaver>(value),
    );
  }
}

String _$scanSaverHash() => r'1ce38bf08457b0aa8edf9802c6996dafbefce139';
