// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Absolute app-documents directory — overridden in main() after
/// path_provider resolves it, so path lookup is synchronous app-wide.

@ProviderFor(storageDir)
final storageDirProvider = StorageDirProvider._();

/// Absolute app-documents directory — overridden in main() after
/// path_provider resolves it, so path lookup is synchronous app-wide.

final class StorageDirProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Absolute app-documents directory — overridden in main() after
  /// path_provider resolves it, so path lookup is synchronous app-wide.
  StorageDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageDirHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return storageDir(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$storageDirHash() => r'53edf3674f88ef5a48ec67fd2ffc29ca3e140f61';

/// Maps stored relative file names (`pages/<id>.jpg`) to absolute paths.

@ProviderFor(resolvePath)
final resolvePathProvider = ResolvePathProvider._();

/// Maps stored relative file names (`pages/<id>.jpg`) to absolute paths.

final class ResolvePathProvider
    extends
        $FunctionalProvider<
          String Function(String),
          String Function(String),
          String Function(String)
        >
    with $Provider<String Function(String)> {
  /// Maps stored relative file names (`pages/<id>.jpg`) to absolute paths.
  ResolvePathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resolvePathProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resolvePathHash();

  @$internal
  @override
  $ProviderElement<String Function(String)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  String Function(String) create(Ref ref) {
    return resolvePath(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String Function(String) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String Function(String)>(value),
    );
  }
}

String _$resolvePathHash() => r'289cd2d3dcf609c946f46dd745d3ae63caa1d1ff';

@ProviderFor(documentsBox)
final documentsBoxProvider = DocumentsBoxProvider._();

final class DocumentsBoxProvider
    extends $FunctionalProvider<Box<String>, Box<String>, Box<String>>
    with $Provider<Box<String>> {
  DocumentsBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentsBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentsBoxHash();

  @$internal
  @override
  $ProviderElement<Box<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Box<String> create(Ref ref) {
    return documentsBox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Box<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Box<String>>(value),
    );
  }
}

String _$documentsBoxHash() => r'45f4056ecd9516d9d7128ae2b980ee4149252e41';

@ProviderFor(foldersBox)
final foldersBoxProvider = FoldersBoxProvider._();

final class FoldersBoxProvider
    extends $FunctionalProvider<Box<String>, Box<String>, Box<String>>
    with $Provider<Box<String>> {
  FoldersBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foldersBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foldersBoxHash();

  @$internal
  @override
  $ProviderElement<Box<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Box<String> create(Ref ref) {
    return foldersBox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Box<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Box<String>>(value),
    );
  }
}

String _$foldersBoxHash() => r'860a90a1d0600427c671598ccef455a1cf0c5629';

@ProviderFor(prefsBox)
final prefsBoxProvider = PrefsBoxProvider._();

final class PrefsBoxProvider
    extends $FunctionalProvider<Box<String>, Box<String>, Box<String>>
    with $Provider<Box<String>> {
  PrefsBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prefsBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prefsBoxHash();

  @$internal
  @override
  $ProviderElement<Box<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Box<String> create(Ref ref) {
    return prefsBox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Box<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Box<String>>(value),
    );
  }
}

String _$prefsBoxHash() => r'c182ad6626f36b390681fa98962f761b85608675';

@ProviderFor(scannerService)
final scannerServiceProvider = ScannerServiceProvider._();

final class ScannerServiceProvider
    extends $FunctionalProvider<ScannerService, ScannerService, ScannerService>
    with $Provider<ScannerService> {
  ScannerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scannerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scannerServiceHash();

  @$internal
  @override
  $ProviderElement<ScannerService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScannerService create(Ref ref) {
    return scannerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScannerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScannerService>(value),
    );
  }
}

String _$scannerServiceHash() => r'833addf1af96578e9d9afc69c61342ed547da8f6';

@ProviderFor(pdfService)
final pdfServiceProvider = PdfServiceProvider._();

final class PdfServiceProvider
    extends $FunctionalProvider<PdfService, PdfService, PdfService>
    with $Provider<PdfService> {
  PdfServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfServiceHash();

  @$internal
  @override
  $ProviderElement<PdfService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PdfService create(Ref ref) {
    return pdfService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfService>(value),
    );
  }
}

String _$pdfServiceHash() => r'4eb86aa15c0be818e7b05ca16744d9376c1ffc3d';

@ProviderFor(exportService)
final exportServiceProvider = ExportServiceProvider._();

final class ExportServiceProvider
    extends $FunctionalProvider<ExportService, ExportService, ExportService>
    with $Provider<ExportService> {
  ExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportServiceHash();

  @$internal
  @override
  $ProviderElement<ExportService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportService create(Ref ref) {
    return exportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportService>(value),
    );
  }
}

String _$exportServiceHash() => r'f9265a90fabeee2632e20022e47e0797ad1e34c2';

@ProviderFor(ocrService)
final ocrServiceProvider = OcrServiceProvider._();

final class OcrServiceProvider
    extends $FunctionalProvider<OcrService, OcrService, OcrService>
    with $Provider<OcrService> {
  OcrServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ocrServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ocrServiceHash();

  @$internal
  @override
  $ProviderElement<OcrService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OcrService create(Ref ref) {
    return ocrService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OcrService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OcrService>(value),
    );
  }
}

String _$ocrServiceHash() => r'baba53bfc5f788ddfabe6743c52cface9d1513d9';

@ProviderFor(appReviewService)
final appReviewServiceProvider = AppReviewServiceProvider._();

final class AppReviewServiceProvider
    extends
        $FunctionalProvider<
          AppReviewService,
          AppReviewService,
          AppReviewService
        >
    with $Provider<AppReviewService> {
  AppReviewServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appReviewServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appReviewServiceHash();

  @$internal
  @override
  $ProviderElement<AppReviewService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppReviewService create(Ref ref) {
    return appReviewService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppReviewService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppReviewService>(value),
    );
  }
}

String _$appReviewServiceHash() => r'f29cabb8f486d9b65033c6411a684060f572f816';
