import '../../models/source_rule.dart';
import '../common/balanced_text_scanner.dart';
import 'request_executor.dart';
import 'url_options.dart';
import 'url_placeholder.dart';

class AnalyzeUrl {
  const AnalyzeUrl({
    this.placeholder = const LegadoUrlPlaceholder(),
    this.scanner = const BalancedTextScanner(),
  });

  final LegadoUrlPlaceholder placeholder;
  final BalancedTextScanner scanner;

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
    final index = scanner.indexWhereTopLevel(
      rawUrl,
      ',',
      (index) => rawUrl.substring(index + 1).trimLeft().startsWith('{'),
    );
    if (index < 0) return SplitLegadoUrlOptions(rawUrl, null);

    return SplitLegadoUrlOptions(
      rawUrl.substring(0, index),
      rawUrl.substring(index + 1).trimLeft(),
    );
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
