// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanFolder _$ScanFolderFromJson(Map<String, dynamic> json) => _ScanFolder(
  id: json['id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  modifiedAt: DateTime.parse(json['modifiedAt'] as String),
);

Map<String, dynamic> _$ScanFolderToJson(_ScanFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'modifiedAt': instance.modifiedAt.toIso8601String(),
    };
