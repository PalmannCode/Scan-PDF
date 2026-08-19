import 'dart:io';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scanpdf/config/app_config.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService.instance,
);

/// Optional Amplitude facade. Missing configuration is an intentional no-op
/// for local builds; production CI supplies the public project API key.
class AnalyticsService {
  AnalyticsService._();

  static final instance = AnalyticsService._();

  Amplitude? _client;
  bool _ready = false;
  String? _userId;
  String _subscriptionStatus = 'free';

  Future<void> initialize() async {
    if (!AppConfig.hasAmplitude || _client != null) return;
    final client = Amplitude(
      Configuration(
        apiKey: AppConfig.amplitudeApiKey,
        instanceName: 'scan_pdf',
      ),
    );
    _ready = await client.isBuilt;
    if (_ready) _client = client;
  }

  Future<void> setUser(String? userId) async {
    final previous = _userId;
    _userId = userId;
    if (!_ready) return;
    if (userId == null) {
      // Only clear the native identity when an identified user actually goes
      // away; an anonymous launch keeps its existing device id.
      if (previous != null) await _client?.reset();
    } else if (userId.length >= 5) {
      await _client?.setUserId(userId);
    }
  }

  /// Clears the Amplitude identity (userId and deviceId) so events recorded
  /// after sign-out or account deletion start a fresh anonymous user instead
  /// of being attributed to the previous account.
  Future<void> reset() async {
    _userId = null;
    if (_ready) await _client?.reset();
  }

  void setSubscriptionStatus(bool active) {
    _subscriptionStatus = active ? 'plus' : 'free';
  }

  Future<void> track(
    String eventType, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!_ready) return;
    final clean = <String, dynamic>{
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'app_version': '1.0.0',
      'subscription_status': _subscriptionStatus,
      ...properties,
    }..removeWhere((_, value) => value == null);
    await _client?.track(
      BaseEvent(eventType, userId: _userId, eventProperties: clean),
    );
  }

  Future<void> flush() async {
    if (_ready) await _client?.flush();
  }
}
