import 'package:scanpdf/shared/models/scan_folder.dart';

abstract class FolderRepository {
  List<ScanFolder> getAll();

  Future<void> upsert(ScanFolder folder);

  Future<void> delete(String id);
}
