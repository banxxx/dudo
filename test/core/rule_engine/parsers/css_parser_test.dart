import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/parsers/css_parser.dart';
import 'package:dudo/core/rule_engine/parsers/default_html_rule_parser.dart';
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
      const parser = CssParser();

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
      const parser = CssParser();

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
      const parser = CssParser();

      expect(
        parser.parseString(html, RuleChain.parse('main > article@data-id')),
        '1',
      );
    });

    test('supports text selector and advanced index selections', () {
      const html = '''
        <ul>
          <li>第一本</li>
          <li>第二本</li>
          <li>第三本</li>
          <li>第四本</li>
        </ul>
        <div><span>包含目标</span><b>忽略</b></div>
      ''';
      const parser = CssParser();

      expect(
        parser.parseString(html, RuleChain.parse('text.包含目标@text')),
        '包含目标',
      );
      expect(
        parser.parseList(html, RuleChain.parse('tag.li[0,2]@text')),
        ['第一本', '第三本'],
      );
      expect(
        parser.parseList(html, RuleChain.parse('tag.li[!1]@text')),
        ['第一本', '第三本', '第四本'],
      );
      expect(
        parser.parseList(html, RuleChain.parse('tag.li[0:4:2]@text')),
        ['第一本', '第三本'],
      );
      expect(
        parser.parseList(html, RuleChain.parse('tag.li[3:1]@text')),
        ['第四本', '第三本'],
      );
    });

    test('supports ownText textNodes all and cleans script style from html',
        () {
      const html = '''
        <article>
          直接文本
          <p>段落</p>
          中间文本
          <script>bad()</script>
          <style>.bad { color: red; }</style>
        </article>
      ''';
      const parser = CssParser();

      expect(
        parser.parseString(html, RuleChain.parse('tag.article@ownText')),
        '直接文本 中间文本',
      );
      expect(
        parser.parseString(html, RuleChain.parse('tag.article@textNodes')),
        '直接文本\n中间文本',
      );
      expect(
        parser.parseString(html, RuleChain.parse('tag.article@text')),
        '直接文本 段落 中间文本',
      );
      expect(
        parser.parseString(html, RuleChain.parse('tag.article@html')),
        isNot(contains('bad')),
      );
      expect(
        parser.parseString(html, RuleChain.parse('tag.article@all')),
        contains('<script>bad()</script>'),
      );
    });
  });

  group('DefaultHtmlRuleParser', () {
    test('is the migrated Legado default HTML parser', () {
      const html = '<div class="book"><a href="/book">三体</a></div>';
      const parser = DefaultHtmlRuleParser();

      expect(
        parser.parseString(html, RuleChain.parse('class.book@tag.a@text')),
        '三体',
      );
    });
  });
}
