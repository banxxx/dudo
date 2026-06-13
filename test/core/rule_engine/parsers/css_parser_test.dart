import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/parsers/css_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CssParser', () {
    test('supports common Legado selector tokens', () {
      const html = '''
        <div class="result">
          <a href="/book/1"><span class="name">三体</span></a>
          <span class="author">刘慈欣</span>
        </div>
      ''';
      final parser = CssParser();

      final nodes = parser.parseElements(
        html,
        RuleChain.parse('class.result'),
      );

      expect(nodes, hasLength(1));
      expect(
        parser.parseString(
            nodes.single, RuleChain.parse('tag.a@tag.span@text')),
        '三体',
      );
      expect(
        parser.parseString(nodes.single, RuleChain.parse('class.author@text')),
        '刘慈欣',
      );
      expect(
        parser.parseString(nodes.single, RuleChain.parse('tag.a@href')),
        '/book/1',
      );
    });

    test('supports Legado range and index selectors', () {
      const html = '''
        <table class="cytable">
          <tr><td>header</td></tr>
          <tr><td><a href="/onebook.php?novelid=1">第一本</a></td></tr>
          <tr><td><a href="/onebook.php?novelid=2">第二本</a></td></tr>
          <tr><td><a href="/onebook.php?novelid=3">第三本</a></td></tr>
        </table>
      ''';
      final parser = CssParser();

      final nodes = parser.parseElements(
        html,
        RuleChain.parse('class.cytable@tag.tr[1:3]@tag.a[0]'),
      );

      expect(nodes, hasLength(2));
      expect(parser.parseString(nodes.first, RuleChain.parse('text')), '第一本');
      expect(parser.parseString(nodes.last, RuleChain.parse('href')),
          '/onebook.php?novelid=2');
    });

    test('keeps regular CSS selector behavior', () {
      const html = '<main><article data-id="1">正文</article></main>';
      final parser = CssParser();

      expect(
        parser.parseString(html, RuleChain.parse('main > article@data-id')),
        '1',
      );
    });
  });
}
