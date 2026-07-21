import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_progress.freezed.dart';
part 'event_progress.g.dart';

/// Receipt Rescue Challenge progress. Only accrues while the event window
/// is live; document ids are tracked so deleting and rescanning the same
/// receipt cannot double-count.
@freezed
abstract class EventProgress with _$EventProgress {
  const EventProgress._();

  const factory EventProgress({
    @Default(<String>[]) List<String> rescuedDocIds,
    DateTime? completedAt,
  }) = _EventProgress;

  factory EventProgress.fromJson(Map<String, dynamic> json) =>
      _$EventProgressFromJson(json);

  int get rescuedCount => rescuedDocIds.length;
}
