import 'package:dudo/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('dudo light color tokens match the design spec', () {
    expect(DudoColors.paperBackground, const Color(0xFFF8F4EA));
    expect(DudoColors.surface, const Color(0xFFFFFBF2));
    expect(DudoColors.primary, const Color(0xFF5E6F5B));
    expect(DudoColors.textPrimary, const Color(0xFF25251F));
    expect(DudoColors.outline, const Color(0xFFD8CDBB));
  });

  testWidgets('bookshelf page renders the home screen design sections',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BookshelfPage(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('今日阅读'), findsOneWidget);
    expect(find.text('晚上好，继续沉入书页'), findsOneWidget);
    expect(find.text('继续阅读'), findsOneWidget);
    expect(find.text('三体 · 第 24 章'), findsOneWidget);
    expect(find.text('找书'), findsOneWidget);
    expect(find.text('书签'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('为你精选'), findsOneWidget);
    expect(find.text('本周节奏'), findsOneWidget);
  });
}
