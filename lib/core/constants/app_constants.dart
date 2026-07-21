abstract class AppConstants {
  static const String appName = 'Scan PDF: Genius Expert Editor';
  static const String appNameShort = 'Scan PDF';
  static const String bundleId = 'com.futurafund.scanpdf';
  static const String appStoreId = '6792221523';
  static const String appStoreUrl =
      'https://apps.apple.com/app/id$appStoreId';

  /// EXACT auto-renewable subscription product ID from App Store Connect
  /// (Monetization > Subscriptions). Intentionally EMPTY until created in
  /// ASC — never guess this value: a mismatch makes queryProductDetails
  /// return nothing and the paywall shows its store-unavailable state.
  static const String plusProductId = '';

  /// Fallback offer copy from Jira SUBAPPS-129 §7, shown when the live
  /// store price has not loaded.
  static const String plusFallbackPrice = r'$3.99/week';
  static const String plusTrialText = '3 days free';

  /// Completed core actions (saved documents) before the in-app review
  /// prompt may fire. Guideline 5.6.3: never on first launch.
  static const int reviewEngagementThreshold = 4;

  /// Receipt Rescue Challenge — In-App Event (time-boxed, Guideline 2.3.13).
  /// Dates confirmed by the user; ASC event must be created with the same.
  static final DateTime eventStart = DateTime(2026, 8, 17);
  static final DateTime eventEnd = DateTime(2026, 9, 17, 23, 59, 59);
  static const int eventGoal = 15;
  static const String eventScheme = 'scanpdf';
  static const String eventHost = 'receipt-rescue';
  static const String eventDeepLink = '$eventScheme://$eventHost';

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  static const String defaultOcrBundle = 'Latin Bundle';
}
