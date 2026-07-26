import 'package:floatick/features/todos/presentation/widgets/todo_markdown.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('remote Markdown images render a local placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: TodoMarkdownContent(
              content: '![Release diagram](https://example.com/diagram.png)',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.text('Release diagram'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
