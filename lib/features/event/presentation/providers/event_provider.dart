import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/features/event/domain/event_phase.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/shared/models/event_progress.dart';

part 'event_provider.g.dart';

@Riverpod(keepAlive: true)
class ReceiptRescue extends _$ReceiptRescue {
  @override
  EventProgress build() =>
      ref.read(appStateRepositoryProvider).loadEventProgress();

  /// Credits a rescued receipt. Only accrues during the live window and
  /// never double-counts a document.
  Future<void> recordRescue(String documentId) async {
    if (currentEventPhase() != EventPhase.live) return;
    if (state.rescuedDocIds.contains(documentId)) return;

    var next = state.copyWith(
      rescuedDocIds: [...state.rescuedDocIds, documentId],
    );
    if (next.rescuedCount >= AppConstants.eventGoal &&
        next.completedAt == null) {
      next = next.copyWith(completedAt: DateTime.now());
      Haptics.success();
    }
    state = next;
    await ref.read(appStateRepositoryProvider).saveEventProgress(next);
  }
}
