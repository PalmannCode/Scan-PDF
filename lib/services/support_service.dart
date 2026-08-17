import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';

final supportServiceProvider = Provider<SupportService>(
  (ref) => const SupportService(),
);

class SupportService {
  const SupportService();

  Future<void> createPriorityTicket({
    required String subject,
    required String message,
  }) async {
    if (!AppConfig.hasSupabase || !BackendRuntime.supabaseReady) {
      throw StateError('Priority Support needs a configured Supabase backend.');
    }
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Sign in to use Priority Support.');
    await client.from('support_tickets').insert({
      'user_id': user.id,
      'subject': subject.trim(),
      'message': message.trim(),
      'priority': 'priority',
      'status': 'open',
    });
  }
}
