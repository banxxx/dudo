import 'package:flutter/material.dart';

import '../../data/reader_document_source.dart';

class ReaderCatalogSheet extends StatelessWidget {
  const ReaderCatalogSheet({
    super.key,
    required this.source,
    required this.bookId,
  });

  final ReaderDocumentSource source;
  final String bookId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<ReaderChapterMetaPage>(
        future: source.loadChapterMetas(
          bookId: bookId,
          offset: 0,
          limit: 200,
        ),
        builder: (context, snapshot) {
          final page = snapshot.data;
          if (page == null) {
            return const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return ListView.builder(
            key: const ValueKey('reader-engine-catalog-sheet'),
            itemCount: page.items.length,
            itemBuilder: (context, index) {
              final item = page.items[index];
              return ListTile(
                title: Text(item.title),
                onTap: () => Navigator.of(context).pop(item.index),
              );
            },
          );
        },
      ),
    );
  }
}
