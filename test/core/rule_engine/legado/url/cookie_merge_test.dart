import 'package:dudo/core/rule_engine/legado/url/cookie_merge.dart';
import 'package:dudo/core/rule_engine/legado/url/persistent_cookie_store.dart';
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

  group('PersistentLegadoCookieStore', () {
    test('persists cookies through persistence adapter', () async {
      final persistence = _MemoryCookiePersistence();
      final store = PersistentLegadoCookieStore.withPersistence(
        persistence: persistence,
      );
      await store.init();
      store.saveFromResponse(
        Uri.parse('https://source.example/path'),
        const ['sid=abc; Path=/; HttpOnly', 'theme=dark; Max-Age=3600'],
      );

      final restored = PersistentLegadoCookieStore.withPersistence(
        persistence: persistence,
      );
      await restored.init();

      expect(
        restored.cookieFor(Uri.parse('https://source.example/next')),
        'sid=abc; theme=dark',
      );
    });

    test('keeps persisted cookies isolated by host', () async {
      final persistence = _MemoryCookiePersistence();
      final store = PersistentLegadoCookieStore.withPersistence(
        persistence: persistence,
      );
      await store.init();
      store
        ..saveFromResponse(Uri.parse('https://a.example/path'), const ['sid=a'])
        ..saveFromResponse(
            Uri.parse('https://b.example/path'), const ['sid=b']);

      final restored = PersistentLegadoCookieStore.withPersistence(
        persistence: persistence,
      );
      await restored.init();

      expect(restored.cookieFor(Uri.parse('https://a.example/next')), 'sid=a');
      expect(restored.cookieFor(Uri.parse('https://b.example/next')), 'sid=b');
    });
  });
}

class _MemoryCookiePersistence implements LegadoCookiePersistence {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  void write(String key, String value) {
    values[key] = value;
  }
}
