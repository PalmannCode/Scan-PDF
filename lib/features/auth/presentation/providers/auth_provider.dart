import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/features/auth/data/auth_service.dart';
import 'package:scanpdf/services/analytics_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(analyticsServiceProvider)),
);

final authUserProvider = StreamProvider<User?>((ref) async* {
  final service = ref.watch(authServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  final current = service.currentUser;
  // Emit the known state FIRST. Awaiting the Amplitude SDK before the first
  // yield gates this provider's initial value on a third-party network call —
  // and anything awaiting `authUserProvider.future` (Document AI) then hangs
  // forever if that call is slow. Analytics is never on a user-facing path.
  yield current;
  unawaited(analytics.setUser(current?.id));
  await for (final user in service.userChanges) {
    yield user;
    unawaited(analytics.setUser(user?.id));
    if (user != null) {
      unawaited(
        analytics.track(
          'sign_in_completed',
          properties: {'provider': user.appMetadata['provider'] ?? 'unknown'},
        ),
      );
    }
  }
});
