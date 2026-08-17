/// Converts only app-authored errors into display copy. Unknown provider,
/// network, platform, and stack details are intentionally replaced.
String userMessageFor(Object error, {required String fallback}) {
  if (error is StateError) return error.message.toString();
  if (error is UnsupportedError) return error.message.toString();
  if (error is FormatException && error.message.isNotEmpty) {
    return error.message;
  }
  return fallback;
}
