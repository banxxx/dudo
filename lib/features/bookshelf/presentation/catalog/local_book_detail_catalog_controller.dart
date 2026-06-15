import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/messages/app_message.dart';
import '../../../../shared/messages/app_message_service.dart';
import '../../application/bookshelf_providers.dart';

/// 本地书籍目录控制器。
///
/// 本地书籍只依赖本地文件路径和 TXT 章节分析服务，不走在线书源规则。
/// 这块逻辑单独放置，避免和在线目录的分页、书源规则、网络刷新混在一起。
class LocalBookDetailCatalogController {
  const LocalBookDetailCatalogController({required this.ref});

  final WidgetRef ref;

  bool canRefresh(Book book) {
    return book.localPath?.isNotEmpty ?? false;
  }

  void refresh(Book book, {required String title}) {
    final localPath = book.localPath;
    if (localPath == null || localPath.isEmpty) return;

    ref.read(localBookChapterAnalysisServiceProvider).analyzeInBackground(
          bookId: book.id,
          localPath: localPath,
        );
    ref.read(appMessageServiceProvider).info(
          '正在重新分析本地目录',
          title: title,
          position: AppMessagePosition.top,
          dedupeKey: 'book-detail-more-$title',
        );
  }
}
