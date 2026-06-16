import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dudo/core/rule_engine/legado/common/legado_trace.dart';
import 'package:dudo/core/rule_engine/legado/legado_runtime.dart';
import 'package:dudo/core/rule_engine/legado/url/request_executor.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentPipeline', () {
    test('parses simple HTML content with CSS rules', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/chapter/1.html'),
          body: '''
            <html><body>
              <h1 class="title">Chapter&nbsp;1</h1>
              <article id="content">
                <p>Line&nbsp;1</p>
                <p>Line 2</p>
              </article>
            </body></html>
          ''',
        ),
      );

      final content = await runtime.loadContent(
        _htmlContentSource(),
        'https://source.example/chapter/1.html',
      );

      expect(content, isNotNull);
      expect(content!.title, 'Chapter 1');
      expect(content.content, 'Line 1\nLine 2');
      expect(content.nextContentUrl, isNull);
    });

    test('falls back to common JSON content fields when JS rule fails',
        () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse(
            'https://source.example/api/chapterContent?chapterId=1',
          ),
          contentType: 'application/json; charset=utf-8',
          body: jsonEncode({
            'chapterId': '1',
            'chapterName': 'Chapter 1',
            'chapterIntro': 'Intro&nbsp;text',
            'sayBody': 'Line 1<br/>Line 2',
          }),
        ),
      );

      final content = await runtime.loadContent(
        _jsonContentSource(),
        'https://source.example/api/chapterContent?chapterId=1',
      );

      expect(content, isNotNull);
      expect(content!.content, contains('Intro text'));
      expect(content.content, contains('Line 1\nLine 2'));
    });

    test('applies bodyJs before parsing content rule', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/api/chapter'),
          body: 'Plain body',
        ),
      );

      final content = await runtime.loadContent(
        _bodyJsContentSource(),
        'https://source.example/api/chapter,'
        '{"bodyJs":"\\"<article><p>\\" + result + \\"</p></article>\\""}',
      );

      expect(content, isNotNull);
      expect(content!.content, 'Plain body');
    });

    test('applies sourceRegex before parsing content rule', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/chapter'),
          body:
              '<html><script>window.__DATA__={"content":"Extracted body"}</script></html>',
        ),
      );

      final content = await runtime.loadContent(
        _sourceRegexContentSource(),
        'https://source.example/chapter,'
        '{"sourceRegex":"window\\\\.__DATA__=({[\\\\s\\\\S]*?})</script>"}',
      );

      expect(content, isNotNull);
      expect(content!.content, 'Extracted body');
    });

    test('writes response Set-Cookie back into next content request', () async {
      final executor = _SequenceExecutor([
        _FakeResponse(
          finalUri: Uri.parse('https://source.example/page1'),
          body: jsonEncode({
            'content': 'Page 1',
            'next': 'https://source.example/page2',
          }),
          headers: {
            'content-type': ['application/json; charset=utf-8'],
            'set-cookie': ['sid=abc; Path=/; HttpOnly'],
          },
        ),
        _FakeResponse(
          finalUri: Uri.parse('https://source.example/page2'),
          body: jsonEncode({'content': 'Page 2'}),
          headers: {
            'content-type': ['application/json; charset=utf-8'],
          },
        ),
      ]);
      final runtime = LegadoRuntime.create(executor: executor);

      final content = await runtime.loadContent(
        _multiPageJsonContentSource(),
        'https://source.example/page1',
      );

      expect(content, isNotNull);
      expect(content!.content, 'Page 1\n\nPage 2');
      expect(executor.requests, hasLength(2));
      expect(executor.requests[1].headers['Cookie'], 'sid=abc');
    });

    test('stops when nextContentUrl points to a visited page', () async {
      final executor = _SequenceExecutor([
        _FakeResponse(
          finalUri: Uri.parse('https://source.example/page1'),
          body: jsonEncode({
            'content': 'Page 1',
            'next': 'https://source.example/page2',
          }),
          headers: {
            'content-type': ['application/json; charset=utf-8'],
          },
        ),
        _FakeResponse(
          finalUri: Uri.parse('https://source.example/page2'),
          body: jsonEncode({
            'content': 'Page 2',
            'next': 'https://source.example/page1',
          }),
          headers: {
            'content-type': ['application/json; charset=utf-8'],
          },
        ),
      ]);
      final runtime = LegadoRuntime.create(executor: executor);

      final content = await runtime.loadContent(
        _multiPageJsonContentSource(),
        'https://source.example/page1',
      );

      expect(content, isNotNull);
      expect(content!.content, 'Page 1\n\nPage 2');
      expect(content.nextContentUrl, 'https://source.example/page1');
      expect(executor.requests, hasLength(2));
    });

    test('throws structured exception when parsed content is empty', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/empty'),
          body: '<html><body><article id="content"></article></body></html>',
        ),
      );

      await expectLater(
        runtime.loadContent(
            _htmlContentSource(), 'https://source.example/empty'),
        throwsA(
          isA<LegadoRuntimeException>()
              .having((error) => error.stage, 'stage', 'content')
              .having((error) => error.message, 'message', 'content is empty')
              .having(
                (error) => error.trace?.events,
                'trace events',
                contains('contentUrl:https://source.example/empty'),
              ),
        ),
      );
    });

    test('throws clear exception for unsupported WebView request mode',
        () async {
      final executor = _ThrowingExecutor();
      final runtime = LegadoRuntime.create(executor: executor);

      await expectLater(
        runtime.loadContent(
          _htmlContentSource(),
          'https://source.example/webview,{"webView":true}',
        ),
        throwsA(
          isA<LegadoRuntimeException>()
              .having((error) => error.stage, 'stage', 'content')
              .having(
                (error) => error.message,
                'message',
                'WebView request mode is not supported yet',
              )
              .having(
                (error) => error.trace?.events,
                'trace events',
                contains('content.url.webView:blocked'),
              ),
        ),
      );
      expect(executor.called, isFalse);
    });
  });
}

SourceRule _htmlContentSource() {
  return const SourceRule(
    id: 'source',
    name: 'Source',
    url: 'https://source.example/',
    content: ContentRule(
      title: 'class.title@text',
      content: 'id.content@tag.p@text',
    ),
  );
}

SourceRule _jsonContentSource() {
  return const SourceRule(
    id: 'source',
    name: 'Source',
    url: 'https://source.example/',
    content: ContentRule(
      content: '<js> missingFunction(result) </js>',
    ),
  );
}

SourceRule _bodyJsContentSource() {
  return const SourceRule(
    id: 'source',
    name: 'Source',
    url: 'https://source.example/',
    content: ContentRule(
      content: 'tag.p@text',
    ),
  );
}

SourceRule _sourceRegexContentSource() {
  return const SourceRule(
    id: 'source',
    name: 'Source',
    url: 'https://source.example/',
    content: ContentRule(
      content: r'$.content',
    ),
  );
}

SourceRule _multiPageJsonContentSource() {
  return const SourceRule(
    id: 'source',
    name: 'Source',
    url: 'https://source.example/',
    content: ContentRule(
      content: r'$.content',
      nextContentUrl: r'$.next',
    ),
  );
}

class _FakeExecutor implements LegadoRequestExecutor {
  const _FakeExecutor({
    required this.finalUri,
    required this.body,
    this.contentType = 'text/html; charset=utf-8',
  });

  final Uri finalUri;
  final String body;
  final String contentType;

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) async {
    return LegadoHttpResponse(
      bytes: utf8.encode(body),
      finalUri: finalUri,
      headers: Headers.fromMap({
        'content-type': [contentType],
      }),
      statusCode: 200,
    );
  }
}

class _SequenceExecutor implements LegadoRequestExecutor {
  _SequenceExecutor(this._responses);

  final List<_FakeResponse> _responses;
  final List<LegadoRequest> requests = [];

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) async {
    requests.add(request);
    final response = _responses[requests.length - 1];
    return LegadoHttpResponse(
      bytes: utf8.encode(response.body),
      finalUri: response.finalUri,
      headers: Headers.fromMap(response.headers),
      statusCode: 200,
    );
  }
}

class _FakeResponse {
  const _FakeResponse({
    required this.finalUri,
    required this.body,
    required this.headers,
  });

  final Uri finalUri;
  final String body;
  final Map<String, List<String>> headers;
}

class _ThrowingExecutor implements LegadoRequestExecutor {
  bool called = false;

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) {
    called = true;
    throw StateError('executor should not be called');
  }
}
