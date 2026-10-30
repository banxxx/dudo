import 'package:dudo/features/settings/about/presentation/about_licenses_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Stream<LicenseEntry> demoLicenses() {
    return Stream<LicenseEntry>.fromIterable([
      const LicenseEntryWithLineBreaks(
        ['demo_pkg', 'other_pkg'],
        'Demo MIT License text',
      ),
      const LicenseEntryWithLineBreaks(['zeta_pkg'], 'Zeta BSD License text'),
    ]);
  }

  testWidgets('groups real license entries by package', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AboutLicensesPage(licenses: demoLicenses())),
    );
    await tester.pumpAndSettle();

    expect(find.text('demo_pkg'), findsOneWidget);
    expect(find.text('other_pkg'), findsOneWidget);
    expect(find.text('zeta_pkg'), findsOneWidget);
    expect(find.textContaining('共 3 个开源组件'), findsOneWidget);
  });

  testWidgets('expanding a package reveals its license text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AboutLicensesPage(licenses: demoLicenses())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Demo MIT License text'), findsNothing);

    await tester.tap(find.text('demo_pkg'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Demo MIT License text'), findsOneWidget);
    expect(find.text('收起许可证'), findsOneWidget);
  });

  testWidgets('search filters packages and reports an empty result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AboutLicensesPage(licenses: demoLicenses())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zeta');
    await tester.pumpAndSettle();

    expect(find.text('demo_pkg'), findsNothing);
    expect(find.text('zeta_pkg'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.pumpAndSettle();

    expect(find.textContaining('没有匹配'), findsOneWidget);
  });
}
