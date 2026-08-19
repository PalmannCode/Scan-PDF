import 'package:intl/intl.dart';

/// Default document-name patterns.
///
/// These are ICU date patterns, where *every* unquoted letter is a format
/// specifier. The literal word must therefore be wrapped in single quotes —
/// otherwise `DateFormat('Scan yyyy-MM-dd HH.mm')` parses S, c, a and n as
/// fields and names the document `00018AMn 2026-08-18 08.41`. It does not
/// throw, so the mistake is silent.
abstract class FileNameFormats {
  static const String scan = "'Scan' yyyy-MM-dd HH.mm";
  static const String document = "'Document' yyyyMMdd-HHmm";
  static const String receipt = "'Receipt' yyyyMMdd";

  static const List<String> all = [scan, document, receipt];

  /// Patterns shipped before the quoting fix, still persisted in Hive and in
  /// `user_settings.default_file_name_format` for existing installs.
  static const Map<String, String> _legacy = {
    'Scan yyyy-MM-dd HH.mm': scan,
    'Document yyyyMMdd-HHmm': document,
    'Receipt yyyyMMdd': receipt,
  };

  /// Upgrades a stored pattern to its quoted form. Unknown patterns pass
  /// through untouched so a user-set value is never silently rewritten.
  static String normalize(String pattern) => _legacy[pattern] ?? pattern;

  /// Formats [when] with [pattern], falling back to the default scan name if
  /// the pattern is unusable.
  ///
  /// A malformed pattern does not always throw — an unterminated quote makes
  /// `DateFormat` return an empty string — and an empty name would leave the
  /// save sheet with nothing to submit, so blank output falls back too.
  static String format(String pattern, DateTime when) {
    try {
      final name = DateFormat(normalize(pattern)).format(when).trim();
      if (name.isNotEmpty) return name;
    } catch (_) {
      // Fall through to the default below.
    }
    return DateFormat(scan).format(when);
  }
}
