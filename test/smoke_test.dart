import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // We intentionally do NOT pump the full `DudoApp` here, because it depends
  // on `Hive.initFlutter`, path_provider, flutter_tts and audio_service — all
  // of which require a real platform. Once a fake/in-memory bootstrap is
  // added, this can be re-enabled.
  testWidgets('placeholder smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('dudo')))),
    );
    expect(find.text('dudo'), findsOneWidget);
  });
}
