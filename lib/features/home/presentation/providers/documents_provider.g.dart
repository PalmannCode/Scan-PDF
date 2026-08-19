// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(documentRepository)
final documentRepositoryProvider = DocumentRepositoryProvider._();

final class DocumentRepositoryProvider
    extends
        $FunctionalProvider<
          DocumentRepository,
          DocumentRepository,
          DocumentRepository
        >
    with $Provider<DocumentRepository> {
  DocumentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentRepositoryHash();

  @$internal
  @override
  $ProviderElement<DocumentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DocumentRepository create(Ref ref) {
    return documentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentRepository>(value),
    );
  }
}

String _$documentRepositoryHash() =>
    r'42bc7cb331db36d3e244993a52c8e47fca1b4401';

/// Whole library (including trash); screens slice it via the computed
/// providers below.

@ProviderFor(Documents)
final documentsProvider = DocumentsProvider._();

/// Whole library (including trash); screens slice it via the computed
/// providers below.
final class DocumentsProvider
    extends $NotifierProvider<Documents, List<ScanDocument>> {
  /// Whole library (including trash); screens slice it via the computed
  /// providers below.
  DocumentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentsHash();

  @$internal
  @override
  Documents create() => Documents();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ScanDocument> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ScanDocument>>(value),
    );
  }
}

String _$documentsHash() => r'c88365e9bed49fd2bd821c6becf560b1146029fd';

/// Whole library (including trash); screens slice it via the computed
/// providers below.

abstract class _$Documents extends $Notifier<List<ScanDocument>> {
  List<ScanDocument> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ScanDocument>, List<ScanDocument>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ScanDocument>, List<ScanDocument>>,
              List<ScanDocument>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(activeDocuments)
final activeDocumentsProvider = ActiveDocumentsProvider._();

final class ActiveDocumentsProvider
    extends
        $FunctionalProvider<
          List<ScanDocument>,
          List<ScanDocument>,
          List<ScanDocument>
        >
    with $Provider<List<ScanDocument>> {
  ActiveDocumentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDocumentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDocumentsHash();

  @$internal
  @override
  $ProviderElement<List<ScanDocument>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ScanDocument> create(Ref ref) {
    return activeDocuments(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ScanDocument> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ScanDocument>>(value),
    );
  }
}

String _$activeDocumentsHash() => r'd48226470aa8e798ae5b612467da5e8a3cac4acf';

@ProviderFor(trashedDocuments)
final trashedDocumentsProvider = TrashedDocumentsProvider._();

final class TrashedDocumentsProvider
    extends
        $FunctionalProvider<
          List<ScanDocument>,
          List<ScanDocument>,
          List<ScanDocument>
        >
    with $Provider<List<ScanDocument>> {
  TrashedDocumentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trashedDocumentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trashedDocumentsHash();

  @$internal
  @override
  $ProviderElement<List<ScanDocument>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ScanDocument> create(Ref ref) {
    return trashedDocuments(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ScanDocument> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ScanDocument>>(value),
    );
  }
}

String _$trashedDocumentsHash() => r'56e0d2d609aa64d5cc88c4277b65700365e28345';

@ProviderFor(documentById)
final documentByIdProvider = DocumentByIdFamily._();

final class DocumentByIdProvider
    extends $FunctionalProvider<ScanDocument?, ScanDocument?, ScanDocument?>
    with $Provider<ScanDocument?> {
  DocumentByIdProvider._({
    required DocumentByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentByIdHash();

  @override
  String toString() {
    return r'documentByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ScanDocument?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScanDocument? create(Ref ref) {
    final argument = this.argument as String;
    return documentById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanDocument? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanDocument?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentByIdHash() => r'39da667e5c76676e0b29aecbb6c91a30f28b0059';

final class DocumentByIdFamily extends $Family
    with $FunctionalFamilyOverride<ScanDocument?, String> {
  DocumentByIdFamily._()
    : super(
        retry: null,
        name: r'documentByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DocumentByIdProvider call(String id) =>
      DocumentByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'documentByIdProvider';
}
