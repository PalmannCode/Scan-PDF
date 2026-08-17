import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:scanpdf/shared/models/event_progress.dart';
import 'package:scanpdf/shared/models/scan_settings.dart';

/// Preferences + small app state living in the prefs box: settings JSON,
/// onboarding flag, engagement counter, Plus entitlement, event progress.
class AppStateRepository {
  AppStateRepository(this._box);

  final Box<String> _box;

  static const _kSettings = 'settings';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kSavedCount = 'saved_documents_count';
  static const _kPlusActive = 'plus_active';
  static const _kEventProgress = 'event_progress';

  ScanSettings loadSettings() {
    final raw = _box.get(_kSettings);
    if (raw == null) return const ScanSettings();
    try {
      return ScanSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ScanSettings();
    }
  }

  Future<void> saveSettings(ScanSettings settings) =>
      _box.put(_kSettings, jsonEncode(settings.toJson()));

  bool get onboardingDone => _box.get(_kOnboardingDone) == 'true';

  Future<void> completeOnboarding() => _box.put(_kOnboardingDone, 'true');

  int get savedDocumentsCount =>
      int.tryParse(_box.get(_kSavedCount) ?? '0') ?? 0;

  Future<int> incrementSavedDocuments() async {
    final next = savedDocumentsCount + 1;
    await _box.put(_kSavedCount, '$next');
    return next;
  }

  bool get plusActive => _box.get(_kPlusActive) == 'true';

  Future<void> setPlusActive(bool active) =>
      _box.put(_kPlusActive, active ? 'true' : 'false');

  EventProgress loadEventProgress() {
    final raw = _box.get(_kEventProgress);
    if (raw == null) return const EventProgress();
    try {
      return EventProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const EventProgress();
    }
  }

  Future<void> saveEventProgress(EventProgress progress) =>
      _box.put(_kEventProgress, jsonEncode(progress.toJson()));

  /// Read synchronously by the router redirect on every navigation.
  static bool onboardingDoneSync(Box<String> box) =>
      box.get(_kOnboardingDone) == 'true';
}
