import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:scanpdf/core/constants/app_constants.dart';

/// Guideline 5.6.3-compliant review prompt: fires at most once per
/// install, only after [AppConstants.reviewEngagementThreshold] completed
/// core actions (saved documents), never at launch or during onboarding.
class AppReviewService {
  AppReviewService(this._prefs);

  final Box<String> _prefs;
  static const _kRequested = 'review_requested';

  Future<void> maybeRequestReview(int engagementCount) async {
    if (_prefs.get(_kRequested) == 'true') return;
    if (engagementCount < AppConstants.reviewEngagementThreshold) return;
    await _prefs.put(_kRequested, 'true');
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Review availability is best-effort; never surface a failure.
    }
  }

  /// Debug-only helper for testing the prompt flow.
  Future<void> resetReviewRequest() async {
    if (!kDebugMode) return;
    await _prefs.delete(_kRequested);
  }
}
