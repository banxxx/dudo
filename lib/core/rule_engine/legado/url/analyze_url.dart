import '../../models/source_rule.dart';
import 'request_executor.dart';
import 'url_options.dart';
import 'url_placeholder.dart';

class AnalyzeUrl {
  const AnalyzeUrl({this.placeholder = const LegadoUrlPlaceholder()});

  final LegadoUrlPlaceholder placeholder;

  LegadoRequest compileSearch({
    required SourceRule source,
    required String rawUrl,
    required String keyword,
    int page = 1,
  }) {
    final analyzedUrl = _analyzeSearchUrl(rawUrl, keyword, page);
    final replaced = placeholder.apply(
      rawUrl: analyzedUrl,
      keyword: keyword,
      page: page,
    );
    final split = splitOptions(replaced);
    final options = LegadoUrlOptions.parse(split.optionJson);
    final url = Uri.parse(source.url).resolve(split.url.trim()).toString();
    final headers = <String, String>{
      ...source.headers,
      ...options.headers,
    };
    return LegadoRequest(
      url: url,
      method: options.method,
      headers: headers,
      body: options.body,
      charset: options.charset,
    );
  }

  SplitLegadoUrlOptions splitOptions(String rawUrl) {
    var braceDepth = 0;
    var bracketDepth = 0;
    var parenDepth = 0;
    var quote = '';
    var escaped = false;

    for (var i = 0; i < rawUrl.length - 1; i++) {
      final char = rawUrl[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (quote.isNotEmpty) {
        if (char == quote) quote = '';
        continue;
      }
      if (char == '"' || char == "'") {
        quote = char;
        continue;
      }
      switch (char) {
        case '{':
          braceDepth += 1;
        case '}':
          if (braceDepth > 0) braceDepth -= 1;
        case '[':
          bracketDepth += 1;
        case ']':
          if (bracketDepth > 0) bracketDepth -= 1;
        case '(':
          parenDepth += 1;
        case ')':
          if (parenDepth > 0) parenDepth -= 1;
        case ',':
          if (braceDepth == 0 && bracketDepth == 0 && parenDepth == 0) {
            final rest = rawUrl.substring(i + 1).trimLeft();
            if (rest.startsWith('{')) {
              return SplitLegadoUrlOptions(rawUrl.substring(0, i), rest);
            }
          }
      }
    }
    return SplitLegadoUrlOptions(rawUrl, null);
  }

  String _analyzeSearchUrl(String rawUrl, String keyword, int page) {
    final text = rawUrl.trim();
    if (!text.toLowerCase().startsWith('@js:')) return rawUrl;

    // Temporary compatibility while the JS engine abstraction is introduced.
    // This preserves the previously supported authorized JJWXC-style fixture
    // without baking this behavior into the final runtime architecture.
    final encodedKeyword = Uri.encodeQueryComponent(keyword);
    if (keyword.startsWith('##')) {
      return 'https://android.jjwxc.net/androidapi/search?versionCode=191&keyword=$encodedKeyword&type=1&page=$page&searchType=8&sortMode=DESC';
    }
    return 'http://www.jjwxc.net/bookbase.php?searchkeywords=$encodedKeyword&page=$page,{"charset":"gbk"}';
  }
}
