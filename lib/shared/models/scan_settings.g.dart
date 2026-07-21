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
  CameraMode.document: 'document',
  CameraMode.text: 'text',
};
