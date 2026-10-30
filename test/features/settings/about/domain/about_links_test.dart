import 'package:dudo/features/settings/about/domain/about_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('links point at the project repository', () {
    expect(AboutLinks.repository.toString(), 'https://github.com/banxxx/dudo');
    expect(
      AboutLinks.feedback.toString(),
      'https://github.com/banxxx/dudo/issues/new',
    );
  });

  test('display renders the raw URL for fallback messages', () {
    expect(
      AboutLinks.display(AboutLinks.repository),
      'https://github.com/banxxx/dudo',
    );
  });
}
