import 'package:flutter_test/flutter_test.dart';
import 'package:scanpdf/services/app_icon_service.dart';

void main() {
  test('alternate icon catalog matches the Jira options', () {
    expect(AppIconService.options.map((option) => option.id), [
      'default',
      'dark',
      'orange',
      'minimal',
      'plus',
    ]);
    expect(AppIconService.options.first.nativeName, isNull);
    expect(
      AppIconService.options.where((option) => option.plusOnly).single.id,
      'plus',
    );
    expect(
      AppIconService.options
          .skip(1)
          .every(
            (option) =>
                option.nativeName != null && option.assetPath.endsWith('.png'),
          ),
      isTrue,
    );
  });
}
