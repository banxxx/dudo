import '../common/balanced_text_scanner.dart';

enum LegadoRuleDelimiter { pipeline, fallback, append, interleave }

class RuleAnalyzer {
  const RuleAnalyzer({this.scanner = const BalancedTextScanner()});

  final BalancedTextScanner scanner;

  List<String> split(String rule, LegadoRuleDelimiter delimiter) {
    final token = switch (delimiter) {
      LegadoRuleDelimiter.pipeline => '@',
      LegadoRuleDelimiter.fallback => '||',
      LegadoRuleDelimiter.append => '&&',
      LegadoRuleDelimiter.interleave => '%%',
    };
    return scanner.split(
      rule,
      token,
      shouldSkipToken: token == '@' ? (buffer, _) => buffer.isEmpty : null,
    );
  }
}
