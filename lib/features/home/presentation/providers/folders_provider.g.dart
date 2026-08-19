// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(folderRepository)
final folderRepositoryProvider = FolderRepositoryProvider._();

final class FolderRepositoryProvider
    extends
        $FunctionalProvider<
          FolderRepository,
          FolderRepository,
          FolderRepository
        >
    with $Provider<FolderRepository> {
  FolderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderRepositoryHash();

  @$internal
  @override
  $ProviderElement<FolderRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FolderRepository create(Ref ref) {
    return folderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FolderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FolderRepository>(value),
    );
  }
}

String _$folderRepositoryHash() => r'47eced03906e0d653ef954a429aa423ba63554cb';

@ProviderFor(Folders)
final foldersProvider = FoldersProvider._();

final class FoldersProvider
    extends $NotifierProvider<Folders, List<ScanFolder>> {
  FoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foldersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foldersHash();

  @$internal
  @override
  Folders create() => Folders();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ScanFolder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ScanFolder>>(value),
    );
  }
}

String _$foldersHash() => r'7ac9db0762e9d1ab685cccb9357e2b626dd48827';

abstract class _$Folders extends $Notifier<List<ScanFolder>> {
  List<ScanFolder> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ScanFolder>, List<ScanFolder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ScanFolder>, List<ScanFolder>>,
              List<ScanFolder>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(folderById)
final folderByIdProvider = FolderByIdFamily._();

final class FolderByIdProvider
    extends $FunctionalProvider<ScanFolder?, ScanFolder?, ScanFolder?>
    with $Provider<ScanFolder?> {
  FolderByIdProvider._({
    required FolderByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'folderByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$folderByIdHash();

  @override
  String toString() {
    return r'folderByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ScanFolder?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScanFolder? create(Ref ref) {
    final argument = this.argument as String;
    return folderById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanFolder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanFolder?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FolderByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$folderByIdHash() => r'c41569e963e7527ae2eb8a3b35302e5c71231c77';

final class FolderByIdFamily extends $Family
    with $FunctionalFamilyOverride<ScanFolder?, String> {
  FolderByIdFamily._()
    : super(
        retry: null,
        name: r'folderByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FolderByIdProvider call(String id) =>
      FolderByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'folderByIdProvider';
}
