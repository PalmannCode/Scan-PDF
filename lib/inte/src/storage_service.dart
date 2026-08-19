import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Tiny SharedPreferences wrapper.
///
/// Persists launch state, attribution params, and optional storefront-routing
/// assignment metadata.
///
/// In particular:
///  * an enters counter — `getEnters() == 0` means first launch (the SDK
///    uses this to pick the first-launch webview vs the returning-users
///    one).
///  * the query params from the most recent webview URL — used to carry
///    attribution across launches so the webview loads with the same
///    `?click_id=…&aff_id=…` params the user landed on originally.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late final SharedPreferences _preferences;

  static const _paramsKey = 'PARAMS';
  static const _entersCountKey = 'ENTERS';
  static const _utcOffsetTopicKey = 'UTC_OFFSET_TOPIC';
  static const _funnelOwnerKey = 'FUNNEL_OWNER';
  static const _funnelRoutingVersionKey = 'FUNNEL_ROUTING_VERSION';
  static const _installationIdKey = 'INSTALLATION_ID';
  static const _webviewFirstOpenKey = 'WEBVIEW_FIRST_OPEN_RECORDED';

  Future<void> setParams(Map<String, dynamic> params) =>
      _preferences.setString(_paramsKey, jsonEncode(params));

  Future<void> increaseEnters() =>
      _preferences.setInt(_entersCountKey, getEnters() + 1);

  /// -1 if never opened. 0 on the first launch (after the first
  /// `increaseEnters` bumps it from -1 to 0… actually it bumps from null
  /// (= -1 default) to 0 then 1. The "first launch" check is
  /// `getEnters() == 0`.
  int getEnters() => _preferences.getInt(_entersCountKey) ?? -1;

  Map<String, dynamic>? getParams() {
    final data = _preferences.getString(_paramsKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>?;
  }

  String? getUtcOffsetTopic() => _preferences.getString(_utcOffsetTopicKey);

  Future<void> setUtcOffsetTopic(String topic) =>
      _preferences.setString(_utcOffsetTopicKey, topic);

  String? getFunnelOwner() => _preferences.getString(_funnelOwnerKey);

  int? getFunnelRoutingVersion() =>
      _preferences.getInt(_funnelRoutingVersionKey);

  Future<void> setFunnelAssignment(String owner, int routingVersion) async {
    await _preferences.setString(_funnelOwnerKey, owner);
    await _preferences.setInt(_funnelRoutingVersionKey, routingVersion);
  }

  Future<String> getOrCreateInstallationId() async {
    final current = _preferences.getString(_installationIdKey);
    if (current != null && current.isNotEmpty) return current;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
    await _preferences.setString(_installationIdKey, id);
    return id;
  }

  bool getHasOpenedWebview() =>
      _preferences.getBool(_webviewFirstOpenKey) ?? false;

  Future<void> markWebviewOpened() =>
      _preferences.setBool(_webviewFirstOpenKey, true);

  static Future<void> initialize() async {
    instance._preferences = await SharedPreferences.getInstance();
  }
}
