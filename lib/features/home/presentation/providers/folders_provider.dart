import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:scanpdf/features/home/data/repositories/folder_repository_impl.dart';
import 'package:scanpdf/features/home/domain/repositories/folder_repository.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/shared/models/scan_folder.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';

part 'folders_provider.g.dart';

@Riverpod(keepAlive: true)
FolderRepository folderRepository(Ref ref) =>
    FolderRepositoryImpl(box: ref.watch(foldersBoxProvider));

@Riverpod(keepAlive: true)
class Folders extends _$Folders {
  FolderRepository get _repo => ref.read(folderRepositoryProvider);

  @override
  List<ScanFolder> build() {
    final folders = _repo.getAll()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return folders;
  }

  void refresh() =>
      state = _repo.getAll()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<ScanFolder> create(String name) async {
    final now = DateTime.now();
    final folder = ScanFolder(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      modifiedAt: now,
    );
    await _repo.upsert(folder);
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track('folder_created', properties: {'folder_id': folder.id});
    return folder;
  }

  Future<void> rename(String id, String name) async {
    final folder = state.where((f) => f.id == id).firstOrNull;
    if (folder == null) return;
    await _repo.upsert(folder.copyWith(name: name, modifiedAt: DateTime.now()));
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track('folder_renamed', properties: {'folder_id': id});
  }

  /// Deletes the folder; its documents fall back to the library root.
  Future<void> delete(String id) async {
    await ref.read(documentsProvider.notifier).detachFolder(id);
    await _repo.delete(id);
    refresh();
    await ref
        .read(analyticsServiceProvider)
        .track('folder_deleted', properties: {'folder_id': id});
  }
}

@riverpod
ScanFolder? folderById(Ref ref, String id) {
  final folders = ref.watch(foldersProvider);
  for (final folder in folders) {
    if (folder.id == id) return folder;
  }
  return null;
}
