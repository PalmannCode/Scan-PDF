import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:scanpdf/shared/models/enums.dart';

part 'scan_page.freezed.dart';
part 'scan_page.g.dart';

/// One scanned/imported page. Image files are stored under the app
/// documents directory as `pages/<id>.jpg` (processed, what the user sees)
/// and `pages/<id>_orig.jpg` (untouched original kept for re-crop /
/// re-filter). Only the id is persisted — absolute paths change between
/// iOS installs.
@freezed
abstract class ScanPage with _$ScanPage {
  const ScanPage._();

  const factory ScanPage({
    required String id,
    @Default(ScanFilter.autoColor) ScanFilter filter,
    @Default('') String ocrText,
  }) = _ScanPage;

  factory ScanPage.fromJson(Map<String, dynamic> json) =>
      _$ScanPageFromJson(json);

  String get processedFileName => 'pages/$id.jpg';
  String get originalFileName => 'pages/${id}_orig.jpg';
  bool get hasOcr => ocrText.trim().isNotEmpty;
}
