import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:scanpdf/shared/models/enums.dart';

part 'scan_settings.freezed.dart';
part 'scan_settings.g.dart';

/// Persisted user preferences (Jira §18 App Settings).
@freezed
abstract class ScanSettings with _$ScanSettings {
  const factory ScanSettings({
    /// 'system' | 'light' | 'dark'
    @Default('system') String themeMode,
    @Default(LibraryViewMode.grid) LibraryViewMode viewMode,
    @Default(LibrarySortMode.dateCreated) LibrarySortMode sortMode,
    @Default(ScanFilter.autoColor) ScanFilter defaultFilter,
    @Default(CameraMode.document) CameraMode defaultCameraMode,
    @Default(true) bool autoOcrAfterScan,
    @Default(true) bool flashAuto,
    @Default(false) bool autoCaptureEnabled,
    @Default('latin') String ocrLanguageBundle,
    @Default('pdf') String defaultExportFormat,
    @Default('Scan yyyy-MM-dd HH.mm') String defaultFileNameFormat,
    @Default('default') String appIcon,
    @Default(false) bool syncEnabled,
    @Default(false) bool autoUploadEnabled,
    @Default('Scanned document: {title}') String defaultEmailSubject,
    @Default('Please find {title} attached.') String defaultEmailBody,
    @Default('') String defaultEmailSignature,
    @Default('pdf') String emailAttachmentFormat,
    @Default(true) bool includeDocumentDate,
    @Default(false) bool diagnosticLogsEnabled,
    @Default(true) bool createSearchablePdf,

    /// JPEG quality for saved page images and PDF embedding (60–95).
    @Default(85) int imageQuality,
  }) = _ScanSettings;

  factory ScanSettings.fromJson(Map<String, dynamic> json) =>
      _$ScanSettingsFromJson(json);
}
