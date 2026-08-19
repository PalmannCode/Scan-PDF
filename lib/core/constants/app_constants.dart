abstract class AppConstants {
  static const String appName = 'Scan PDF: Genius Expert Editor';
  static const String appNameShort = 'Scan PDF';
  static const String bundleId = 'com.futurafund.scanpdf';
  static const String appStoreId = '6792221523';
  static const String appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';

  /// Auto-renewable subscription product IDs as configured in App Store
  /// Connect. Both carry a 3-day introductory offer.
  static const String plusWeeklyProductId = 'scanpdf.plus.weekly';
  static const String plusMonthlyProductId = 'scanpdf.plus.monthly';

  /// Every product the paywall may sell. StoreKit is queried for all of them
  /// and a purchase of any one grants Plus.
  static const Set<String> plusProductIds = {
    plusWeeklyProductId,
    plusMonthlyProductId,
  };

  /// Fallback offer copy shown only until the live localized store price
  /// loads. StoreKit remains the source of truth for displayed prices.
  static const String plusWeeklyFallbackPrice = r'$3.99';
  static const String plusMonthlyFallbackPrice = r'$9.99';
  static const String plusWeeklyPeriod = 'week';
  static const String plusMonthlyPeriod = 'month';
  static const String plusTrialText = '3 days free';

  /// Pre-selected on the paywall: monthly is the lower effective rate.
  static const String plusDefaultProductId = plusMonthlyProductId;

  static String fallbackPriceFor(String productId) =>
      productId == plusWeeklyProductId
      ? plusWeeklyFallbackPrice
      : plusMonthlyFallbackPrice;

  static String periodFor(String productId) =>
      productId == plusWeeklyProductId ? plusWeeklyPeriod : plusMonthlyPeriod;

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
