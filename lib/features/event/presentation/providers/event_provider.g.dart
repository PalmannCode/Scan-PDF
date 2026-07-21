// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReceiptRescue)
final receiptRescueProvider = ReceiptRescueProvider._();

final class ReceiptRescueProvider
    extends $NotifierProvider<ReceiptRescue, EventProgress> {
  ReceiptRescueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptRescueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptRescueHash();

  @$internal
  @override
  ReceiptRescue create() => ReceiptRescue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventProgress>(value),
    );
  }
}

String _$receiptRescueHash() => r'2ac60d7893609e4bfa7491d779b6d376d92c031b';

abstract class _$ReceiptRescue extends $Notifier<EventProgress> {
  EventProgress build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EventProgress, EventProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventProgress, EventProgress>,
              EventProgress,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
