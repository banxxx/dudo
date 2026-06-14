class OnlineSearchBookResult {
  const OnlineSearchBookResult({
    required this.sourceId,
    required this.sourceName,
    required this.name,
    required this.author,
    this.intro,
    this.coverUrl,
    this.bookUrl,
  });

  final String sourceId;
  final String sourceName;
  final String name;
  final String author;
  final String? intro;
  final String? coverUrl;
  final String? bookUrl;
}

class OnlineSearchFailure {
  const OnlineSearchFailure({
    required this.sourceId,
    required this.sourceName,
    required this.message,
    this.diagnostics = const [],
  });

  final String sourceId;
  final String sourceName;
  final String message;
  final List<String> diagnostics;
}

class OnlineSearchResponse {
  const OnlineSearchResponse({
    required this.results,
    required this.failures,
    required this.searchedSourceCount,
    required this.availableSourceCount,
  });

  final List<OnlineSearchBookResult> results;
  final List<OnlineSearchFailure> failures;
  final int searchedSourceCount;
  final int availableSourceCount;

  bool get hasResults => results.isNotEmpty;
  bool get hasFailures => failures.isNotEmpty;
  bool get allSearchedSourcesFailed =>
      searchedSourceCount > 0 &&
      results.isEmpty &&
      failures.length >= searchedSourceCount;
}
