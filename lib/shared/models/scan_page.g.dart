// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanPage _$ScanPageFromJson(Map<String, dynamic> json) => _ScanPage(
  id: json['id'] as String,
  filter:
      $enumDecodeNullable(_$ScanFilterEnumMap, json['filter']) ??
      ScanFilter.autoColor,
  ocrText: json['ocrText'] as String? ?? '',
);

Map<String, dynamic> _$ScanPageToJson(_ScanPage instance) => <String, dynamic>{
  'id': instance.id,
  'filter': _$ScanFilterEnumMap[instance.filter]!,
  'ocrText': instance.ocrText,
};

const _$ScanFilterEnumMap = {
  ScanFilter.autoColor: 'autoColor',
  ScanFilter.original: 'original',
  ScanFilter.blackWhite: 'blackWhite',
  ScanFilter.grayscale: 'grayscale',
  ScanFilter.lighten: 'lighten',
  ScanFilter.highContrast: 'highContrast',
};
