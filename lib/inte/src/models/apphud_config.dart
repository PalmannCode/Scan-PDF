/// Apphud IAP keys returned alongside the app config.
///
/// The SDK doesn't wire Apphud automatically — your app reads these
/// values via `HomeScreenAnalytics.of(context).info?.apphudConfig` and
/// hands them to the Apphud SDK during your own setup.
class ApphudConfig {
  const ApphudConfig({required this.apiKey, required this.productId});

  final String apiKey;
  final String productId;

  static ApphudConfig fromJson(Map<String, dynamic> json) {
    return ApphudConfig(
      apiKey: json['api_key'] as String,
      productId: json['product_id'] as String? ?? '',
    );
  }
}
