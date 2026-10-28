import 'package:dudo/core/rule_engine/legado/common/js_block_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsBlockScanner', () {
    const scanner = JsBlockScanner();

    test('finds a plain closing tag', () {
      const rule = '<js>result + 1</js>@text';

      expect(scanner.findBlockEnd(rule, 4), rule.indexOf('</js>'));
    });

    test('ignores closing tags inside strings', () {
      const rule = '<js>result = "</js>@text";</js>@text';

      expect(scanner.findBlockEnd(rule, 4), rule.lastIndexOf('</js>'));
    });

    test('ignores quotes inside regex literals', () {
      const rule = '<js>\nresult.match(/body":"(.*?)"/)\n</js>\n##Alpha';

      expect(scanner.findBlockEnd(rule, 4), rule.indexOf('</js>'));
    });

    test('handles single-line regex literals containing quotes', () {
      const rule = '<js>result.match(/&v=(.*?)"/)</js>';

      expect(scanner.findBlockEnd(rule, 4), rule.indexOf('</js>'));
    });

    test('ignores closing tags inside line and block comments', () {
      const lineComment = '<js>\n// </js>\nresult\n</js>';
      const blockComment = '<js>\n/* </js> */\nresult\n</js>';

      expect(
        scanner.findBlockEnd(lineComment, 4),
        lineComment.lastIndexOf('</js>'),
      );
      expect(
        scanner.findBlockEnd(blockComment, 4),
        blockComment.lastIndexOf('</js>'),
      );
    });

    test('does not treat division as a regex literal', () {
      const rule = '<js>\na / b / c\n</js>';

      expect(scanner.findBlockEnd(rule, 4), rule.indexOf('</js>'));
    });

    test('falls back to the first closing tag for malformed JavaScript', () {
      const rule = "<js>var x = '/pic/'+id+.jpg';</js>";

      expect(scanner.findBlockEnd(rule, 4), rule.indexOf('</js>'));
    });

    test('returns -1 for an unclosed block', () {
      expect(scanner.findBlockEnd('<js>result', 4), -1);
    });
  });
}
