import 'package:flutter_test/flutter_test.dart';

import 'package:scanpdf/core/constants/app_constants.dart';
import 'package:scanpdf/features/event/domain/deep_link_resolver.dart';
import 'package:scanpdf/features/event/domain/event_phase.dart';

void main() {
  group('deep link resolver', () {
    test('event link routes to the event screen', () {
      expect(
        resolveDeepLink(Uri.parse('scanpdf://receipt-rescue')),
        '/event',
      );
    });

    test('unknown host falls back to home', () {
      expect(resolveDeepLink(Uri.parse('scanpdf://unknown')), '/');
    });

    test('unknown scheme falls back to home', () {
      expect(
        resolveDeepLink(Uri.parse('otherapp://receipt-rescue')),
        '/',
      );
    });

    test('deep link constant matches the resolver contract', () {
      expect(
        resolveDeepLink(Uri.parse(AppConstants.eventDeepLink)),
        '/event',
      );
    });
  });

  group('event phase', () {
    test('before the window is upcoming', () {
      expect(eventPhaseAt(DateTime(2026, 8, 16, 23)), EventPhase.upcoming);
    });

    test('inside the window is live', () {
      expect(eventPhaseAt(DateTime(2026, 8, 17, 0, 1)), EventPhase.live);
      expect(eventPhaseAt(DateTime(2026, 9, 1)), EventPhase.live);
    });

    test('after the window is ended', () {
      expect(eventPhaseAt(DateTime(2026, 9, 18)), EventPhase.ended);
    });
  });
}
