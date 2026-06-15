class OnlineSearchBookResult {
  const OnlineSearchBookResult({
    required this.sourceId,
    required this.sourceName,
    required this.name,
    required this.author,
    this.intro,
    this.coverUrl,
    this.bookUrl,
    this.kind,
    this.lastChapter,
    this.wordCount,
    this.origins = const [],
  });

  final String sourceId;
  final String sourceName;
  final String name;
  final String author;
  final String? intro;
  final String? coverUrl;
  final String? bookUrl;
  final String? kind;
  final String? lastChapter;
  final String? wordCount;
  final List<OnlineSearchOrigin> origins;
}

class OnlineSearchOrigin {
  const OnlineSearchOrigin({
    required this.sourceId,
    required this.sourceName,
    this.bookUrl,
  });

  final String sourceId;
  final String sourceName;
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
    this.completedSourceCount = 0,
    this.isSearching = false,
  });

  final List<OnlineSearchBookResult> results;
  final List<OnlineSearchFailure> failures;
  final int searchedSourceCount;
  final int availableSourceCount;
  final int completedSourceCount;
  final bool isSearching;

  bool get hasResults => results.isNotEmpty;
  bool get hasFailures => failures.isNotEmpty;
  bool get allSearchedSourcesFailed =>
      !isSearching &&
      searchedSourceCount > 0 &&
      results.isEmpty &&
      failures.length >= searchedSourceCount;
}
