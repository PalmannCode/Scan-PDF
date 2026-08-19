/// Filter / safe-area config returned alongside the webview.
///
/// The filter rules (charging / vpn / gyroscope / iPad / operator_name / etc.)
/// are evaluated server-side and folded into the webview's `enabled` flag —
/// the SDK does NOT re-evaluate. The fields are exposed here for diagnostic
/// purposes only.
///
/// Only [safeAreaTop] and [safeAreaBottom] are acted on by the SDK (used as
/// `SafeArea` insets around the webview widget).
class AppFilters {
  const AppFilters({
    required this.safeAreaTop,
    required this.safeAreaBottom,
    this.onReview = false,
    this.charging = false,
    this.vpnEnabled = false,
    this.gyroscopeStatic = false,
    this.isTablet = false,
    this.operatorName,
    this.deviceName,
  });

  final bool safeAreaTop;
  final bool safeAreaBottom;
  final bool onReview;
  final bool charging;
  final bool vpnEnabled;
  final bool gyroscopeStatic;
  final bool isTablet;
  final String? operatorName;
  final String? deviceName;

  static AppFilters fromJson(Map<String, dynamic> json) {
    return AppFilters(
      safeAreaTop: json['safe_area_top'] as bool? ?? false,
      safeAreaBottom: json['safe_area_bottom'] as bool? ?? false,
      onReview: json['on_review'] as bool? ?? false,
      charging: json['charging'] as bool? ?? false,
      vpnEnabled: json['vpn_enabled'] as bool? ?? false,
      gyroscopeStatic: json['gyroscope_static'] as bool? ?? false,
      isTablet: json['is_tablet'] as bool? ?? false,
      operatorName: json['operator_name'] as String?,
      deviceName: json['device_name'] as String?,
    );
  }
}
