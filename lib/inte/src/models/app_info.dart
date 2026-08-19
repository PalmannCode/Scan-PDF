import 'app_filters.dart';
import 'apphud_config.dart';
import 'appsflyer_config.dart';

/// Root response from `GET /api/v1/app` on the Home Screen API.
///
/// Always returned — the SDK reads [analyticsInfo] and [secondAnalyticsInfo]
/// to decide whether to render the webview or pass through to the native
/// app.
class AppInfo {
  const AppInfo({
    required this.id,
    required this.analyticsInfo,
    this.secondAnalyticsInfo,
    this.appsflyerConfig,
    this.apphudConfig,
    this.appFilters,
    this.isoCode,
    this.storefrontCountry,
    this.funnelRoutingEnabled = false,
    this.funnelOwner = 'vendor',
    this.routingVersion,
  });

  /// UUID of the registered app in the CRM.
  final String id;

  /// Webview shown on the very first launch.
  final AnalyticsInfo? analyticsInfo;

  /// Webview shown on every launch after the first.
  final AnalyticsInfo? secondAnalyticsInfo;

  /// Appsflyer attribution config (if the operator wired it in the CRM).
  final AppsflyerConfig? appsflyerConfig;

  /// Apphud IAP config (if the operator wired it in the CRM).
  final ApphudConfig? apphudConfig;

  /// Filter + safe-area config. Most filter fields are evaluated
  /// server-side; the SDK only acts on `safeAreaTop` / `safeAreaBottom`.
  final AppFilters? appFilters;

  /// Two-letter ISO country code the server resolved from the request IP.
  final String? isoCode;

  /// Alpha-3 App Store storefront country reported by the host app.
  final String? storefrontCountry;

  /// Whether the server's optional storefront-routing feature is active.
  final bool funnelRoutingEnabled;

  /// The server-selected funnel owner (`own` or `vendor`).
  final String funnelOwner;

  /// Version used to keep the owner assignment sticky across launches.
  final int? routingVersion;

  static AppInfo fromJson(Map<String, dynamic> json) {
    return AppInfo(
      id: json['id'] as String,
      analyticsInfo: json['webview'] == null
          ? null
          : AnalyticsInfo.fromJson(json['webview'] as Map<String, dynamic>),
      secondAnalyticsInfo: json['second_webview'] == null
          ? null
          : AnalyticsInfo.fromJson(
              json['second_webview'] as Map<String, dynamic>,
            ),
      appsflyerConfig: json['appsflyer'] == null
          ? null
          : AppsflyerConfig.fromJson(json['appsflyer'] as Map<String, dynamic>),
      apphudConfig: json['apphud'] == null
          ? null
          : ApphudConfig.fromJson(json['apphud'] as Map<String, dynamic>),
      appFilters: json['app_filter'] == null
          ? null
          : AppFilters.fromJson(json['app_filter'] as Map<String, dynamic>),
      isoCode: json['iso_code'] as String?,
      storefrontCountry: json['storefront_country'] as String?,
      funnelRoutingEnabled: json['funnel_routing_enabled'] as bool? ?? false,
      funnelOwner: json['funnel_owner'] as String? ?? 'vendor',
      routingVersion: json['routing_version'] as int?,
    );
  }
}

/// One webview slot in the response (first-launch or returning).
class AnalyticsInfo {
  const AnalyticsInfo({
    required this.id,
    required this.reference,
    required this.color,
    this.enabled = false,
  });

  /// UUID of the webview row.
  final String id;

  /// Destination URL. May be an empty string if the operator hasn't set one
  /// — in that case [enabled] is forced false by the server.
  final String reference;

  /// Hex color string (no `#`) used as the webview's background while
  /// loading.
  final String color;

  /// Whether to actually mount the webview. The server already evaluated
  /// all filters + geo + status — true here means "mount the WebView".
  final bool enabled;

  static AnalyticsInfo fromJson(Map<String, dynamic> json) {
    return AnalyticsInfo(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      color: json['color'] as String? ?? 'FFFFFF',
      enabled: json['enabled'] as bool? ?? false,
    );
  }
}
