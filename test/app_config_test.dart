import 'package:flutter_test/flutter_test.dart';
import 'package:scanpdf/config/app_config.dart';

void main() {
  test('production public services are configured', () {
    expect(AppConfig.hasSupabase, isTrue);
    expect(AppConfig.supabaseUrl, 'https://iyxksejttlhtcqwhpuvl.supabase.co');
    expect(AppConfig.hasAmplitude, isTrue);
    expect(AppConfig.authCallback, 'scanpdf://auth-callback');
  });
}
