// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanDocument _$ScanDocumentFromJson(Map<String, dynamic> json) =>
    _ScanDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      folderId: json['folderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      pages:
          (json['pages'] as List<dynamic>?)
              ?.map((e) => ScanPage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ScanPage>[],
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      ocrAttempted: json['ocrAttempted'] as bool? ?? false,
    );

Map<String, dynamic> _$ScanDocumentToJson(_ScanDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'folderId': instance.folderId,
      'createdAt': instance.createdAt.toIso8601String(),
      'modifiedAt': instance.modifiedAt.toIso8601String(),
      'pages': instance.pages,
      'isDeleted': instance.isDeleted,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'ocrAttempted': instance.ocrAttempted,
    };
