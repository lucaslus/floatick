import 'package:floatick/app/theme/floatick_theme.dart';
import 'package:floatick/features/notes/domain/note_item.dart';
import 'package:floatick/features/notes/presentation/note_editor_drawer.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('blank draft closes without creating a note', (tester) async {
    var saveCount = 0;
    var closeCount = 0;
    await _pumpEditor(
      tester,
      onSave: ({id, required title, required content, required tagIds}) async {
        saveCount += 1;
        return null;
      },
      onClose: () => closeCount += 1,
    );

    expect(find.byKey(const Key('note-document-editor')), findsOneWidget);
    expect(find.text('标题'), findsNothing);
    expect(find.text('内容'), findsNothing);
    expect(
      find.byKey(const Key('floatick-document-title-divider')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.title_rounded), findsNothing);
    expect(find.byKey(const Key('note-template-blank')), findsNothing);
    expect(find.byKey(const Key('note-template-daily')), findsNothing);
    expect(find.byKey(const Key('note-template-weekly')), findsNothing);
    expect(find.byKey(const Key('note-template-monthly')), findsNothing);
    expect(find.byKey(const Key('note-editor-mode-switch')), findsOneWidget);
    expect(find.byKey(const Key('note-editor-tag-button')), findsOneWidget);
    expect(find.text('标签'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('note-editor-tag-button'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('note-editor-mode-switch'))).dx,
      ),
    );
    expect(find.byKey(const Key('note-editor-footer')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('close-note-editor')));
    await tester.pumpAndSettle();

    expect(saveCount, 0);
    expect(closeCount, 1);
  });

  testWidgets('content is autosaved after the debounce', (tester) async {
    final saves =
        <({String? id, String title, String content, List<String> tagIds})>[];
    await _pumpEditor(
      tester,
      availableTags: <TodoTag>[
        TodoTag(
          id: 'tag-work',
          name: 'Work',
          colorValue: 0xFF14B8A6,
          createdAt: DateTime.utc(2026, 8, 3),
        ),
      ],
      assignedTagIds: const <String>['tag-work'],
      onSave: ({id, required title, required content, required tagIds}) async {
        saves.add((id: id, title: title, content: content, tagIds: tagIds));
        return NoteItem(
          id: id ?? 'note-1',
          title: title.isEmpty ? 'First thought' : title,
          content: content,
          createdAt: DateTime.utc(2026, 8, 3, 8),
          updatedAt: DateTime.utc(2026, 8, 3, 8),
          tagIds: tagIds,
        );
      },
      onClose: () {},
    );

    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'First thought',
    );
    await tester.pump(const Duration(milliseconds: 449));
    expect(saves, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(saves.single.content, 'First thought');
    expect(saves.single.tagIds, <String>['tag-work']);
    expect(find.byKey(const Key('note-editor-tag-tag-work')), findsOneWidget);
    expect(find.text('已自动保存'), findsOneWidget);

    await tester.tap(find.byKey(const Key('note-markdown-preview-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-content-preview')), findsOneWidget);
    expect(find.byKey(const Key('note-content-field')), findsNothing);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required SaveNoteDraft onSave,
  required VoidCallback onClose,
  List<TodoTag> availableTags = const <TodoTag>[],
  List<String> assignedTagIds = const <String>[],
}) async {
  tester.view.physicalSize = const Size(500, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final closeFocusNode = FocusNode();
  addTearDown(closeFocusNode.dispose);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFloatickTheme(Brightness.dark),
      home: Scaffold(
        body: SizedBox(
          width: 440,
          height: 590,
          child: NoteEditorDrawer(
            item: null,
            availableTags: availableTags,
            assignedTagIds: assignedTagIds,
            isOpen: true,
            onSave: onSave,
            onOpenTagAssignment: () {},
            onClose: onClose,
            closeFocusNode: closeFocusNode,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
