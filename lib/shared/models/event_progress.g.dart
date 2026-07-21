// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventProgress _$EventProgressFromJson(Map<String, dynamic> json) =>
    _EventProgress(
      rescuedDocIds:
          (json['rescuedDocIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$EventProgressToJson(_EventProgress instance) =>
    <String, dynamic>{
      'rescuedDocIds': instance.rescuedDocIds,
      'completedAt': instance.completedAt?.toIso8601String(),
    };
