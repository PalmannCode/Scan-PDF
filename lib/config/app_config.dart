/// Compile-time configuration for public client identifiers.
///
/// Production builds may override these with `--dart-define`. These defaults
/// are public client identifiers and are intentionally embedded in the app.
/// OpenAI, App Store Server API, and Supabase service-role credentials live
/// only in Supabase Edge Function secrets.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iyxksejttlhtcqwhpuvl.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5eGtzZWp0dGxodGNxd2hwdXZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY5NzY2NDcsImV4cCI6MjEwMjU1MjY0N30.Nb_qmtLZK9GxL700A55LjGxz_xa97sRaxtZcODo4bDM',
  );
  static const amplitudeApiKey = String.fromEnvironment(
    'AMPLITUDE_API_KEY',
    defaultValue: '42c18f271213478381ec34bc0625cfdf',
  );

  static const authCallback = 'scanpdf://auth-callback';

  static bool get hasSupabase =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.isNotEmpty &&
      !supabasePublishableKey.contains('REPLACE_ME');

  static bool get hasAmplitude =>
      amplitudeApiKey.isNotEmpty && !amplitudeApiKey.contains('REPLACE_ME');
}

/// Records whether optional network infrastructure initialized successfully.
/// Guest mode intentionally remains available when no public configuration is
/// supplied, while configured production builds can surface initialization
/// failures instead of silently pretending cloud features work.
abstract final class BackendRuntime {
  static bool supabaseReady = false;
  static Object? supabaseError;
}
