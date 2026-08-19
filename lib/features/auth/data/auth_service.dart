import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/services/analytics_service.dart';

class BackendNotConfiguredException implements Exception {
  const BackendNotConfiguredException();

  @override
  String toString() =>
      'Cloud services could not initialize. Check your connection and try '
      'again.';
}

/// Supabase Auth gateway for guest, native Apple, and passwordless email flows.
class AuthService {
  AuthService(this._analytics);

  final AnalyticsService _analytics;

  bool get isAvailable => AppConfig.hasSupabase && BackendRuntime.supabaseReady;

  SupabaseClient get _client {
    if (!isAvailable) throw const BackendNotConfiguredException();
    return Supabase.instance.client;
  }

  User? get currentUser => isAvailable ? _client.auth.currentUser : null;

  Stream<User?> get userChanges => isAvailable
      ? _client.auth.onAuthStateChange.map((event) => event.session?.user)
      : Stream<User?>.value(null);

  Future<void> signInWithApple() async {
    await _analytics.track(
      'sign_in_started',
      properties: {'provider': 'apple'},
    );
    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple did not return an identity token.');
      }
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      final given = credential.givenName?.trim();
      final family = credential.familyName?.trim();
      final fullName = [
        if (given != null && given.isNotEmpty) given,
        if (family != null && family.isNotEmpty) family,
      ].join(' ');
      if (fullName.isNotEmpty) {
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': fullName,
              'given_name': given,
              'family_name': family,
            },
          ),
        );
      }
      await _analytics.setUser(response.user?.id);
      await _analytics.track(
        'sign_in_completed',
        properties: {'provider': 'apple'},
      );
    } catch (error) {
      await _analytics.track(
        'sign_in_failed',
        properties: {
          'provider': 'apple',
          'error_code': error.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }

  Future<void> sendEmailLink(String email) async {
    await _analytics.track(
      'sign_in_started',
      properties: {'provider': 'email'},
    );
    try {
      await _client.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: AppConfig.authCallback,
        shouldCreateUser: true,
      );
    } catch (error) {
      await _analytics.track(
        'sign_in_failed',
        properties: {
          'provider': 'email',
          'error_code': error.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _analytics.track('sign_out_clicked');
    await _analytics.reset();
  }

  Future<void> deleteAccount() async {
    await _client.functions.invoke('delete_account');
    await _analytics.track('account_deleted');
    await _client.auth.signOut(scope: SignOutScope.global);
    await _analytics.reset();
  }
}
