import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:carrier_info/carrier_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:retry/retry.dart';
import 'package:rxdart/subjects.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'models/app_info.dart';
import 'storage_service.dart';

typedef FlutterAnalyticsEventCallback =
    FutureOr<void> Function(String eventName, Map<String, Object?> properties);

/// Configuration the host app passes to [FlutterAnalytics].
///
/// The only required field is [appAnalyticsUrl] — the per-app domain the
/// operator points at the Home Screen API CRM via registrar URL forwarding
/// (e.g. `http://waterlineapi.site`).
class FlutterAnalyticsConfig {
  FlutterAnalyticsConfig({
    required this.appAnalyticsUrl,
    this.enableFunnelRouting = true,
    this.onEvent,
  });

  /// Per-app domain that forwards to the CRM. Use `http://` (not `https://`)
  /// since most registrar URL forwarders don't auto-provision TLS.
  final String appAnalyticsUrl;

  /// Enables App Store storefront request fields. This defaults on so new SDK
  /// integrations are routing-ready; the dashboard switch remains the sole
  /// authority that can activate an app's funnel routing.
  final bool enableFunnelRouting;

  /// Optional independent analytics sink. Callback errors are isolated so
  /// they can never interrupt config loading, vendor tracking, or the WebView.
  final FlutterAnalyticsEventCallback? onEvent;

  /// App row UUID, populated after the config fetch resolves.
  late String appId;

  /// Stream of the app's config (single event per launch — config is fetched
  /// once at boot and cached for the rest of the session).
  Stream<AppInfo> get status => _FlutterAnalyticsConfigImpl.instance.status;

  /// Sync accessor to the cached config, null until the fetch resolves.
  AppInfo? get info => _FlutterAnalyticsConfigImpl.instance.info;

  /// Stream of attribution params fed into the webview URL. Populated by
  /// attribution SDKs (Appsflyer / etc.) when they resolve — your app
  /// pushes onto this stream from whatever attribution source you use.
  BehaviorSubject<Map<String, dynamic>> get analyticsParams =>
      _FlutterAnalyticsConfigImpl.instance.analyticsParams;

  Future<void> initialize() =>
      _FlutterAnalyticsConfigImpl.instance.initialize(this);

  Future<void> notifyAboutUrlChange(String url) =>
      _FlutterAnalyticsConfigImpl.instance.notifyAboutUrlChange(url);

  Future<void> notifyWebviewOpened(String funnelUrl) =>
      _FlutterAnalyticsConfigImpl.instance.notifyWebviewOpened(funnelUrl);
}

class _FlutterAnalyticsConfigImpl {
  _FlutterAnalyticsConfigImpl._();

  static final _FlutterAnalyticsConfigImpl instance =
      _FlutterAnalyticsConfigImpl._();

  late final FlutterAnalyticsConfig _config;
  late final _FlutterAnalyticsConfigRepository _repository;

  final StreamController<AppInfo> _statusController =
      StreamController.broadcast();
  Stream<AppInfo> get status => _statusController.stream.asBroadcastStream();

  AppInfo? info;

  BehaviorSubject<Map<String, dynamic>> analyticsParams = BehaviorSubject();

  static const MethodChannel _storefrontChannel = MethodChannel(
    'home_screen_api/storefront',
  );

  late bool _isFirstOpen;
  late String _installationId;
  late String _appVersion;
  String? _storefrontCountry;

  Future<void> initialize(FlutterAnalyticsConfig config) async {
    _config = config;
    await StorageService.initialize();
    await StorageService.instance.increaseEnters();
    _isFirstOpen = StorageService.instance.getEnters() == 0;
    _installationId = await StorageService.instance.getOrCreateInstallationId();

    _repository = _FlutterAnalyticsConfigRepository(
      baseUri: Uri.parse(config.appAnalyticsUrl),
    );

    // Collect device signals in parallel — the server uses these to decide
    // which config variant to return (battery / vpn / gyroscope / tablet / SIM).
    int? batteryLevel;
    bool? charging;
    bool? vpnEnabled;
    bool? gyroscopeStatic;
    bool? isTablet;
    String? sim;

    try {
      batteryLevel = await Battery().batteryLevel;
      charging = await Battery().batteryState == BatteryState.charging;
    } catch (_) {}

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      vpnEnabled =
          connectivityResults.contains(ConnectivityResult.vpn) ||
          connectivityResults.contains(ConnectivityResult.other);
    } catch (_) {}

    try {
      if (Platform.isIOS) {
        final IosCarrierData carrierInfo = await CarrierInfo.getIosInfo();
        sim = carrierInfo.carrierData.firstOrNull?.carrierName;
      }
    } catch (e) {
      log(e.toString());
    }

    try {
      isTablet = Device.get().isTablet;
    } catch (e) {
      log(e.toString());
    }

    try {
      StreamSubscription? streamSubscription;
      streamSubscription = gyroscopeEventStream().listen(
        (_) {
          gyroscopeStatic = false;
          streamSubscription?.cancel();
        },
        onError: (_) {
          gyroscopeStatic = true;
          streamSubscription?.cancel();
        },
      );
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      gyroscopeStatic = true;
      log(e.toString());
    } finally {
      gyroscopeStatic ??= true;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final bundle = packageInfo.packageName;
    _appVersion = packageInfo.version;
    _storefrontCountry = await _getStorefrontCountry();
    final savedFunnelOwner = StorageService.instance.getFunnelOwner();
    final savedRoutingVersion = StorageService.instance
        .getFunnelRoutingVersion();
    final AppInfo? app = await _repository.fetchAppInfo(
      appBundleIos: Platform.isIOS ? bundle : null,
      appBundleAndroid: Platform.isAndroid ? bundle : null,
      batteryLevel: batteryLevel,
      charging: charging,
      vpnEnabled: vpnEnabled,
      gyroscopeStatic: gyroscopeStatic,
      isTablet: isTablet,
      operatorName: sim,
      storefrontCountry: _storefrontCountry,
      funnelOwner: config.enableFunnelRouting ? savedFunnelOwner : null,
      routingVersion: config.enableFunnelRouting ? savedRoutingVersion : null,
    );

    if (app != null) {
      final assignmentChanged =
          app.funnelRoutingEnabled &&
          app.routingVersion != null &&
          (savedFunnelOwner != app.funnelOwner ||
              savedRoutingVersion != app.routingVersion);
      if (app.funnelRoutingEnabled && app.routingVersion != null) {
        await StorageService.instance.setFunnelAssignment(
          app.funnelOwner,
          app.routingVersion!,
        );
      }
      info = app;
      _config.appId = app.id;
      analyticsParams.add({});
      _statusController.add(app);
      unawaited(_trackLaunchEvents(app, assignmentChanged));
    } else {
      _statusController.addError(const HttpException(''));
    }

    await _initializeFirebase(isoCode: app?.isoCode);
  }

  Future<String?> _getStorefrontCountry() async {
    if (!_config.enableFunnelRouting || !Platform.isIOS) return null;
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final value = await _storefrontChannel.invokeMethod<String>(
          'getStorefrontCountry',
        );
        final normalized = value?.trim().toUpperCase();
        if (normalized != null && RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
          return normalized;
        }
      } catch (e) {
        lastError = e;
      }
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    log(
      'App Store storefront unavailable after retries${lastError == null ? '' : ': $lastError'}',
      name: 'ANALYTICS',
    );
    return null;
  }

  AnalyticsInfo? _selectedAnalytics(AppInfo app) {
    final first = app.analyticsInfo;
    final second = app.secondAnalyticsInfo;
    return StorageService.instance.getEnters() == 0
        ? first
        : ((second?.enabled ?? false) ? second : first);
  }

  Map<String, Object?> _eventProperties(AppInfo app, String funnelUrl) => {
    'storefront_country':
        app.storefrontCountry ?? _storefrontCountry ?? 'UNKNOWN',
    'funnel_owner': app.funnelOwner,
    'installation_id': _installationId,
    'is_first_open': _isFirstOpen,
    'app_version': _appVersion,
    'funnel_url': funnelUrl,
  };

  Future<void> _trackLaunchEvents(AppInfo app, bool assignmentChanged) async {
    final funnelUrl = _selectedAnalytics(app)?.reference ?? '';
    if (_isFirstOpen) {
      await _emitEvent('app_first_open', _eventProperties(app, funnelUrl));
    }
    await _emitEvent('app_open', _eventProperties(app, funnelUrl));
    if (assignmentChanged) {
      await _emitEvent('funnel_routed', _eventProperties(app, funnelUrl));
    }
  }

  Future<void> notifyWebviewOpened(String funnelUrl) async {
    final app = info;
    if (app == null) return;

    final isFirstWebviewOpen = !StorageService.instance.getHasOpenedWebview();
    if (isFirstWebviewOpen) {
      await StorageService.instance.markWebviewOpened();
    }
    await _emitEvent('webview_opened', _eventProperties(app, funnelUrl));
    if (isFirstWebviewOpen) {
      await _emitEvent('webview_first_open', _eventProperties(app, funnelUrl));
    }
  }

  Future<void> _emitEvent(
    String eventName,
    Map<String, Object?> properties,
  ) async {
    final callback = _config.onEvent;
    if (callback == null) return;
    try {
      await callback(eventName, properties);
    } catch (e, s) {
      log(
        'Independent analytics event failed: $eventName — $e',
        name: 'ANALYTICS',
      );
      log(s.toString(), name: 'ANALYTICS');
    }
  }

  Future<void> _initializeFirebase({String? isoCode}) async {
    try {
      FirebaseMessaging.onBackgroundMessage(_notifyAboutPushReceive);
      FirebaseMessaging.onMessage.listen(_notifyAboutPushReceive);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _repository.notifyAboutPushOpen(
          campaignId: message.data['campaign_id'],
          logId: message.data['log_id'],
          isoCode: message.data['iso_code'],
        ),
      );

      await Firebase.initializeApp();

      // App launched cold from a push tap.
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        final data = initialMessage.data;
        unawaited(
          _repository.notifyAboutPushOpen(
            campaignId: data['campaign_id'],
            logId: data['log_id'],
            isoCode: data['iso_code'],
          ),
        );
      }

      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      final timezoneOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      final timezoneName = DateTime.now().timeZoneName;
      final offsetTopic = _utcOffsetTopic(timezoneOffsetMinutes);

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        log('FCM token: $token', name: 'ANALYTICS');
        await _repository.registerDevice(
          fcmToken: token,
          appId: _config.appId,
          isoCode: isoCode,
          timezoneOffsetMinutes: timezoneOffsetMinutes,
          timezoneName: timezoneName,
        );
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        log('FCM token refreshed: $token', name: 'ANALYTICS');
        unawaited(
          _repository.registerDevice(
            fcmToken: token,
            appId: _config.appId,
            isoCode: isoCode,
            timezoneOffsetMinutes: timezoneOffsetMinutes,
            timezoneName: timezoneName,
          ),
        );
      });

      // Broadcast, country, and UTC-offset topics. With one Firebase project
      // per app these topic names are naturally isolated to this app's devices.
      await FirebaseMessaging.instance.subscribeToTopic('all_devices');
      if (isoCode != null) {
        await FirebaseMessaging.instance.subscribeToTopic('country_$isoCode');
      }
      final previousOffsetTopic = StorageService.instance.getUtcOffsetTopic();
      if (previousOffsetTopic != null && previousOffsetTopic != offsetTopic) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          previousOffsetTopic,
        );
      }
      await FirebaseMessaging.instance.subscribeToTopic(offsetTopic);
      await StorageService.instance.setUtcOffsetTopic(offsetTopic);

      log('Initialized firebase', name: 'ANALYTICS');
    } catch (e) {
      log('Unable to initialize firebase', name: 'ANALYTICS');
      log(e.toString(), name: 'ANALYTICS');
    }
  }

  Future<void> notifyAboutUrlChange(String url) async {
    log(url, name: 'URL CHANGE');
    final uri = Uri.parse(url);
    final params = uri.queryParameters;
    if (params.isNotEmpty) {
      await StorageService.instance.setParams(
        Map<String, dynamic>.from(params),
      );
    }
  }
}

String _utcOffsetTopic(int offsetMinutes) {
  final sign = offsetMinutes < 0 ? 'm' : 'p';
  final absolute = offsetMinutes.abs().toString().padLeft(4, '0');
  return 'utc_offset_${sign}$absolute';
}

class _FlutterAnalyticsConfigRepository {
  const _FlutterAnalyticsConfigRepository({required this.baseUri});

  static const String _api = '/api/v1';

  final Uri baseUri;

  Uri _endpoint(String path, [Map<String, String>? queryParameters]) =>
      baseUri.replace(path: path, queryParameters: queryParameters);

  Future<void> notifyAboutPushOpen({
    String? campaignId,
    String? logId,
    String? isoCode,
  }) async {
    try {
      final body = <String, String>{
        if (campaignId != null) 'campaign_id': campaignId,
        if (logId != null) 'log_id': logId,
        if (isoCode != null) 'iso_code': isoCode,
      };

      final url = _endpoint('$_api/push-notifications/opened');
      final response = await retry(
        () => http
            .post(
              url,
              body: jsonEncode(body),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 3)),
        retryIf: (_) => true,
        maxAttempts: 3,
      );
      log(response.body, name: 'ANALYTICS');
    } catch (e, s) {
      log(e.toString(), name: 'API ERROR');
      log(s.toString(), name: 'API ERROR');
    }
  }

  Future<void> registerDevice({
    required String fcmToken,
    required String appId,
    String? isoCode,
    int? timezoneOffsetMinutes,
    String? timezoneName,
  }) async {
    try {
      final body = <String, dynamic>{
        'app_id': appId,
        'fcm_token': fcmToken,
        if (isoCode != null) 'iso_code': isoCode,
        if (timezoneOffsetMinutes != null)
          'timezone_offset_minutes': timezoneOffsetMinutes,
        if (timezoneName != null) 'timezone_name': timezoneName,
      };

      final url = _endpoint('$_api/device-registrations');
      final response = await retry(
        () => http
            .post(
              url,
              body: jsonEncode(body),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 3)),
        retryIf: (_) => true,
        maxAttempts: 3,
      );
      log(response.body, name: 'ANALYTICS');
    } catch (e, s) {
      log(e.toString(), name: 'API ERROR');
      log(s.toString(), name: 'API ERROR');
    }
  }

  Future<AppInfo?> fetchAppInfo({
    String? appBundleIos,
    String? appBundleAndroid,
    bool? charging,
    int? batteryLevel,
    bool? vpnEnabled,
    String? operatorName,
    bool? isTablet,
    bool? gyroscopeStatic,
    String? storefrontCountry,
    String? funnelOwner,
    int? routingVersion,
  }) async {
    try {
      final params = <String, String>{
        if (appBundleIos != null) 'app_bundle_ios': appBundleIos,
        if (appBundleAndroid != null) 'app_bundle_android': appBundleAndroid,
        if (kDebugMode) 'type': 'debug',
        if (!kDebugMode) 'type': 'release',
        if (charging != null) 'charging': charging.toString(),
        if (batteryLevel != null) 'battery_level': batteryLevel.toString(),
        if (vpnEnabled != null) 'vpn_enabled': vpnEnabled.toString(),
        if (gyroscopeStatic != null)
          'gyroscope_static': gyroscopeStatic.toString(),
        if (isTablet != null) 'is_tablet': isTablet.toString(),
        if (operatorName != null) 'operator_name': operatorName,
        if (storefrontCountry != null) 'storefront_country': storefrontCountry,
        if (funnelOwner != null) 'funnel_owner': funnelOwner,
        if (routingVersion != null)
          'routing_version': routingVersion.toString(),
      };

      final url = _endpoint('$_api/app', params);
      final response = await retry(
        () => http.get(url).timeout(const Duration(seconds: 3)),
        retryIf: (_) => true,
        maxAttempts: 5,
      );

      final data = jsonDecode(response.body)['data'];
      if (data == null) return null;
      return AppInfo.fromJson(data as Map<String, dynamic>);
    } catch (e, s) {
      log(e.toString(), name: 'API ERROR');
      log(s.toString(), name: 'API ERROR');
      return null;
    }
  }
}

/// Background isolate push handler. Top-level + `@pragma('vm:entry-point')`
/// is required by Firebase Messaging.
///
/// The host is stored base64-encoded so it can be swapped at build time
/// (e.g. via a sed step in CI) without editing this file.
@pragma('vm:entry-point')
Future<void> _notifyAboutPushReceive(RemoteMessage message) async {
  try {
    final campaignId = message.data['campaign_id'];
    final logId = message.data['log_id'];
    final isoCode = message.data['iso_code'];

    final body = <String, String>{
      if (campaignId != null) 'campaign_id': campaignId.toString(),
      if (logId != null) 'log_id': logId.toString(),
      if (isoCode != null) 'iso_code': isoCode,
    };

    // base64('homescreenapi.site') = 'aG9tZXNjcmVlbmFwaS5zaXRl'.
    // Replace at build time if you point the SDK at a different central host.
    const String encryptedHost = 'aG9tZXNjcmVlbmFwaS5zaXRl';
    final decoded = base64Decode(encryptedHost);
    final host = String.fromCharCodes(decoded);

    final url = Uri.https(host, 'api/push-notifications/received');
    final response = await retry(
      () => http
          .post(
            url,
            body: jsonEncode(body),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3)),
      retryIf: (_) => true,
      maxAttempts: 3,
    );
    log(response.body, name: 'ANALYTICS');
  } catch (e, s) {
    log(e.toString(), name: 'API ERROR');
    log(s.toString(), name: 'API ERROR');
  }
}
