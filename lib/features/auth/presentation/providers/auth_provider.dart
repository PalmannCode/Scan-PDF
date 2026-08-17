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
  await analytics.setUser(current?.id);
  yield current;
  await for (final user in service.userChanges) {
    await analytics.setUser(user?.id);
    if (user != null) {
      await analytics.track(
        'sign_in_completed',
        properties: {'provider': user.appMetadata['provider'] ?? 'unknown'},
      );
    }
    yield user;
  }
});
