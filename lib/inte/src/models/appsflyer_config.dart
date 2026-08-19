/// Appsflyer attribution keys returned alongside the app config.
///
/// The SDK doesn't wire Appsflyer automatically — your app reads these
/// values via `HomeScreenAnalytics.of(context).info?.appsflyerConfig` and
/// hands them to the Appsflyer SDK during your own setup.
class AppsflyerConfig {
  const AppsflyerConfig({required this.devKey, required this.appId});

  final String devKey;
  final String appId;

  static AppsflyerConfig fromJson(Map<String, dynamic> json) {
    return AppsflyerConfig(
      devKey: json['dev_key'] as String,
      appId: json['appsflyer_app_id'] as String,
    );
  }
}
