import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_folder.freezed.dart';
part 'scan_folder.g.dart';

@freezed
abstract class ScanFolder with _$ScanFolder {
  const factory ScanFolder({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _ScanFolder;

  factory ScanFolder.fromJson(Map<String, dynamic> json) =>
      _$ScanFolderFromJson(json);
}
