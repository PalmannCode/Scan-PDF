import 'package:scanpdf/core/constants/app_constants.dart';

/// Pure resolver: custom-scheme URI → in-app route. Unknown links fall
/// back to home so a bad link can never strand the user.
String resolveDeepLink(Uri uri) {
  if (uri.scheme == AppConstants.eventScheme &&
      uri.host == AppConstants.eventHost) {
    return '/event';
  }
  if (uri.scheme == AppConstants.eventScheme && uri.host == 'auth-callback') {
    return '/account';
  }
  return '/';
}
