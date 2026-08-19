// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanSettings _$ScanSettingsFromJson(Map<String, dynamic> json) =>
    _ScanSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      viewMode:
          $enumDecodeNullable(_$LibraryViewModeEnumMap, json['viewMode']) ??
          LibraryViewMode.grid,
      sortMode:
          $enumDecodeNullable(_$LibrarySortModeEnumMap, json['sortMode']) ??
          LibrarySortMode.dateCreated,
      defaultFilter:
          $enumDecodeNullable(_$ScanFilterEnumMap, json['defaultFilter']) ??
          ScanFilter.autoColor,
      defaultCameraMode:
          $enumDecodeNullable(_$CameraModeEnumMap, json['defaultCameraMode']) ??
          CameraMode.document,
      autoOcrAfterScan: json['autoOcrAfterScan'] as bool? ?? true,
      flashAuto: json['flashAuto'] as bool? ?? true,
      autoCaptureEnabled: json['autoCaptureEnabled'] as bool? ?? false,
      ocrLanguageBundle: json['ocrLanguageBundle'] as String? ?? 'latin',
      defaultExportFormat: json['defaultExportFormat'] as String? ?? 'pdf',
      defaultFileNameFormat:
          json['defaultFileNameFormat'] as String? ?? FileNameFormats.scan,
      appIcon: json['appIcon'] as String? ?? 'default',
      syncEnabled: json['syncEnabled'] as bool? ?? false,
      autoUploadEnabled: json['autoUploadEnabled'] as bool? ?? false,
      defaultEmailSubject:
          json['defaultEmailSubject'] as String? ?? 'Scanned document: {title}',
      defaultEmailBody:
          json['defaultEmailBody'] as String? ??
          'Please find {title} attached.',
      defaultEmailSignature: json['defaultEmailSignature'] as String? ?? '',
      emailAttachmentFormat: json['emailAttachmentFormat'] as String? ?? 'pdf',
      includeDocumentDate: json['includeDocumentDate'] as bool? ?? true,
      diagnosticLogsEnabled: json['diagnosticLogsEnabled'] as bool? ?? false,
      createSearchablePdf: json['createSearchablePdf'] as bool? ?? true,
      imageQuality: (json['imageQuality'] as num?)?.toInt() ?? 85,
    );

Map<String, dynamic> _$ScanSettingsToJson(_ScanSettings instance) =>
    <String, dynamic>{
      'themeMode': instance.themeMode,
      'viewMode': _$LibraryViewModeEnumMap[instance.viewMode]!,
      'sortMode': _$LibrarySortModeEnumMap[instance.sortMode]!,
      'defaultFilter': _$ScanFilterEnumMap[instance.defaultFilter]!,
      'defaultCameraMode': _$CameraModeEnumMap[instance.defaultCameraMode]!,
      'autoOcrAfterScan': instance.autoOcrAfterScan,
      'flashAuto': instance.flashAuto,
      'autoCaptureEnabled': instance.autoCaptureEnabled,
      'ocrLanguageBundle': instance.ocrLanguageBundle,
      'defaultExportFormat': instance.defaultExportFormat,
      'defaultFileNameFormat': instance.defaultFileNameFormat,
      'appIcon': instance.appIcon,
      'syncEnabled': instance.syncEnabled,
      'autoUploadEnabled': instance.autoUploadEnabled,
      'defaultEmailSubject': instance.defaultEmailSubject,
      'defaultEmailBody': instance.defaultEmailBody,
      'defaultEmailSignature': instance.defaultEmailSignature,
      'emailAttachmentFormat': instance.emailAttachmentFormat,
      'includeDocumentDate': instance.includeDocumentDate,
      'diagnosticLogsEnabled': instance.diagnosticLogsEnabled,
      'createSearchablePdf': instance.createSearchablePdf,
      'imageQuality': instance.imageQuality,
    };

const _$LibraryViewModeEnumMap = {
  LibraryViewMode.grid: 'grid',
  LibraryViewMode.list: 'list',
};

const _$LibrarySortModeEnumMap = {
  LibrarySortMode.dateCreated: 'dateCreated',
  LibrarySortMode.dateModified: 'dateModified',
  LibrarySortMode.name: 'name',
};

const _$ScanFilterEnumMap = {
  ScanFilter.autoColor: 'autoColor',
  ScanFilter.original: 'original',
  ScanFilter.blackWhite: 'blackWhite',
  ScanFilter.grayscale: 'grayscale',
  ScanFilter.lighten: 'lighten',
  ScanFilter.highContrast: 'highContrast',
};

const _$CameraModeEnumMap = {
  CameraMode.count: 'count',
  CameraMode.measure: 'measure',
  CameraMode.qrCode: 'qrCode',
  CameraMode.document: 'document',
  CameraMode.book: 'book',
  CameraMode.translate: 'translate',
  CameraMode.text: 'text',
};
