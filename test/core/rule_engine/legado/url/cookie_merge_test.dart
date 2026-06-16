import 'package:dudo/core/rule_engine/legado/url/cookie_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryLegadoCookieStore', () {
    test('saves Set-Cookie headers as request cookie pairs', () {
      final store = InMemoryLegadoCookieStore();

      store.saveFromResponse(
        Uri.parse('https://source.example/path'),
        const ['sid=abc; Path=/; HttpOnly', 'theme=dark; Max-Age=3600'],
      );

      expect(
        store.cookieFor(Uri.parse('https://source.example/next')),
        'sid=abc; theme=dark',
      );
    });

    test('overwrites same cookie name and keeps existing values', () {
      final store = InMemoryLegadoCookieStore();
      final uri = Uri.parse('https://source.example/path');

      store.saveFromResponse(uri, const ['sid=old; Path=/', 'theme=dark']);
      store.saveFromResponse(uri, const ['sid=new; Path=/']);

      expect(store.cookieFor(uri), 'sid=new; theme=dark');
    });

    test('keeps cookies isolated by host', () {
      final store = InMemoryLegadoCookieStore();

      store.saveFromResponse(
        Uri.parse('https://a.example/path'),
        const ['sid=a'],
      );
      store.saveFromResponse(
        Uri.parse('https://b.example/path'),
        const ['sid=b'],
      );

      expect(store.cookieFor(Uri.parse('https://a.example/next')), 'sid=a');
      expect(store.cookieFor(Uri.parse('https://b.example/next')), 'sid=b');
    });
  });
}
