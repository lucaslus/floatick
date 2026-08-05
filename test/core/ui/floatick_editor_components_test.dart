import 'package:floatick/app/theme/floatick_theme.dart';
import 'package:floatick/core/ui/floatick_editor_components.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared editor surface owns header, switch, and footer styling', (
    WidgetTester tester,
  ) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);
    var closeCount = 0;
    bool? previewSelection;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloatickTheme(Brightness.dark),
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 520,
            child: FloatickEditorDrawerSurface(
              key: const Key('shared-editor-surface'),
              title: 'Editor title',
              closeTooltip: 'Close editor',
              closeButtonKey: const Key('shared-editor-close'),
              closeFocusNode: closeFocusNode,
              onClose: () => closeCount += 1,
              child: Column(
                children: <Widget>[
                  FloatickEditorModeSwitch(
                    showPreview: false,
                    onChanged: (value) => previewSelection = value,
                  ),
                  const Spacer(),
                  const FloatickEditorFooter(child: Text('Footer')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editor title'), findsOneWidget);
    expect(
      find.byKey(const Key('floatick-editor-mode-switch')),
      findsOneWidget,
    );
    expect(find.text('Footer'), findsOneWidget);

    final surfaceDecoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byKey(const Key('shared-editor-surface')),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(surfaceDecoration.color, const Color(0xFF202A2E));

    await tester.tap(find.byKey(const Key('markdown-preview-tab')));
    expect(previewSelection, isTrue);
    await tester.tap(find.byKey(const Key('shared-editor-close')));
    expect(closeCount, 1);
  });

  testWidgets(
    'document editor visually unifies separate title and content fields',
    (WidgetTester tester) async {
      final titleController = TextEditingController();
      final contentController = TextEditingController();
      final titleFocusNode = FocusNode();
      final contentFocusNode = FocusNode();
      addTearDown(titleController.dispose);
      addTearDown(contentController.dispose);
      addTearDown(titleFocusNode.dispose);
      addTearDown(contentFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFloatickTheme(Brightness.dark),
          home: Scaffold(
            body: SizedBox(
              width: 440,
              height: 420,
              child: FloatickDocumentEditor(
                titleController: titleController,
                contentController: contentController,
                titleFocusNode: titleFocusNode,
                contentFocusNode: contentFocusNode,
                titleHint: 'Optional title',
                contentHint: 'Start writing',
                titleSemanticsLabel: 'Title',
                contentSemanticsLabel: 'Content',
                showPreview: false,
                preview: const Text('Preview body'),
                onPreviewChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('floatick-document-title-divider')),
        findsOneWidget,
      );
      final titleField = tester.widget<TextField>(
        find.byKey(const Key('floatick-document-title-field')),
      );
      final contentField = tester.widget<TextField>(
        find.byKey(const Key('floatick-document-content-field')),
      );
      expect(titleField.decoration?.filled, isFalse);
      expect(titleField.decoration?.border, InputBorder.none);
      expect(contentField.decoration?.filled, isFalse);
      expect(contentField.decoration?.border, InputBorder.none);

      await tester.enterText(
        find.byKey(const Key('floatick-document-title-field')),
        'A title',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(contentFocusNode.hasFocus, isTrue);
    },
  );
}
