import 'package:dudo/features/sources/data/source_import_service.dart';
import 'package:dudo/features/sources/data/source_repository.dart';
import 'package:dudo/features/sources/data/importers/legado_source_importer.dart';
import 'package:dudo/features/sources/domain/source_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeSourceRepository repository;
  late Map<String, String> responses;
  late List<_FetchCall> calls;

  SourceImportService buildService() {
    return SourceImportService(
      repository: repository,
      importers: const [LegadoSourceImporter()],
      fetcher: (url, {withoutUserAgent = false}) async {
        calls.add(_FetchCall(url, withoutUserAgent));
        final response = responses[url];
        if (response == null) {
          throw StateError('unexpected url: $url');
        }
        return response;
      },
    );
  }

  setUp(() {
    repository = _FakeSourceRepository();
    responses = {};
    calls = [];
  });

  test('imports pasted json with a utf-8 bom', () async {
    final result = await buildService().importRuleUrl(
      '\uFEFF[{"bookSourceName":"粘贴源","bookSourceUrl":"https://a.example.com"}]',
    );

    expect(result.insertedCount, 1);
    expect(repository.captured!.candidates.single.name, '粘贴源');
    expect(calls, isEmpty);
  });

  test('fetches a subscription and resolves relative child urls', () async {
    responses['https://example.com/lists/main.json'] =
        '{"sourceUrls":["sub.json","https://other.example.com/absolute.json"]}';
    responses['https://example.com/lists/sub.json'] =
        '[{"bookSourceName":"相对源","bookSourceUrl":"https://a.example.com"}]';
    responses['https://other.example.com/absolute.json'] =
        '{"bookSourceName":"绝对源","bookSourceUrl":"https://b.example.com"}';

    final result = await buildService().importRuleUrl(
      'https://example.com/lists/main.json',
    );

    expect(calls.map((call) => call.url), [
      'https://example.com/lists/main.json',
      'https://example.com/lists/sub.json',
      'https://other.example.com/absolute.json',
    ]);
    expect(result.insertedCount, 2);
    expect(
      repository.captured!.candidates.map((candidate) => candidate.name),
      ['相对源', '绝对源'],
    );
  });

  test('supports the requestWithoutUA suffix', () async {
    responses['https://example.com/no-ua.json'] =
        '[{"bookSourceName":"无UA源","bookSourceUrl":"https://a.example.com"}]';

    await buildService().importRuleUrl(
      'https://example.com/no-ua.json#requestWithoutUA',
    );

    expect(calls.single.url, 'https://example.com/no-ua.json');
    expect(calls.single.withoutUserAgent, isTrue);
  });

  test('resolves sourceUrls in pasted json', () async {
    responses['https://example.com/child.json'] =
        '[{"bookSourceName":"子源","bookSourceUrl":"https://a.example.com"}]';

    final result = await buildService().importRuleUrl(
      '{"sourceUrls":["https://example.com/child.json"]}',
    );

    expect(result.insertedCount, 1);
    expect(repository.captured!.candidates.single.name, '子源');
  });

  test('rejects non-http input', () async {
    await expectLater(
      buildService().importRuleUrl('file:///tmp/sources.json'),
      throwsA(
        isA<SourceImportException>().having(
          (error) => error.message,
          'message',
          '链接格式不正确，请输入 http(s) 地址',
        ),
      ),
    );
  });

  test('stops when a subscription exceeds the depth limit', () async {
    responses['https://example.com/0.json'] =
        '{"sourceUrls":["https://example.com/1.json"]}';
    responses['https://example.com/1.json'] =
        '{"sourceUrls":["https://example.com/2.json"]}';
    responses['https://example.com/2.json'] =
        '{"sourceUrls":["https://example.com/3.json"]}';

    await expectLater(
      buildService().importRuleUrl('https://example.com/0.json'),
      throwsA(
        isA<SourceImportException>().having(
          (error) => error.message,
          'message',
          '订阅层级过深，已停止导入',
        ),
      ),
    );
  });
}

class _FetchCall {
  const _FetchCall(this.url, this.withoutUserAgent);

  final String url;
  final bool withoutUserAgent;
}

class _FakeSourceRepository implements SourceRepository {
  SourceImportParseResult? captured;
  ExistingSourceStrategy? capturedStrategy;

  @override
  Future<SourceImportPersistResult> upsertImportedSources(
    SourceImportParseResult parseResult, {
    ExistingSourceStrategy existingStrategy =
        ExistingSourceStrategy.updateIfNewer,
  }) async {
    captured = parseResult;
    capturedStrategy = existingStrategy;
    return SourceImportPersistResult(
      totalInputCount: parseResult.totalInputCount,
      validCount: parseResult.validCount,
      insertedCount: parseResult.validCount,
      updatedCount: 0,
      skippedExistingCount: 0,
      duplicateInFileCount: parseResult.duplicateInFileCount,
      invalidCount: parseResult.invalidCount,
      nonTextCount: parseResult.nonTextCount,
      searchlessCount: parseResult.searchlessCount,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
