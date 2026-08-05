import 'package:floatick/features/notes/data/note_repository.dart';
import 'package:floatick/features/notes/domain/note_item.dart';
import 'package:floatick/features/notes/presentation/note_panel_content.dart';
import 'package:floatick/features/notes/presentation/note_view_model.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('note list shows shared tags and applies the tag filter', (
    WidgetTester tester,
  ) async {
    final timestamp = DateTime.utc(2026, 8, 3, 8);
    final controller = NoteViewModel(
      repository: _MemoryNoteRepository(<NoteItem>[
        NoteItem(
          id: 'note-work',
          title: 'Work note',
          content: 'Plan the release',
          createdAt: timestamp,
          updatedAt: timestamp,
          tagIds: const <String>['tag-work'],
        ),
        NoteItem(
          id: 'note-personal',
          title: 'Personal note',
          content: 'Buy coffee',
          createdAt: timestamp,
          updatedAt: timestamp,
          tagIds: const <String>['tag-personal'],
        ),
      ]),
    );
    await controller.load();
    final tags = <TodoTag>[
      TodoTag(
        id: 'tag-work',
        name: 'Work',
        colorValue: 0xFF14B8A6,
        createdAt: timestamp,
      ),
      TodoTag(
        id: 'tag-personal',
        name: 'Personal',
        colorValue: 0xFF60A5FA,
        createdAt: timestamp,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 500,
            child: NotePanelContent(
              controller: controller,
              archived: false,
              query: '',
              availableTags: tags,
              selectedTagIds: const <String>{'tag-work'},
              onOpen: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Work note'), findsOneWidget);
    expect(find.text('Personal note'), findsNothing);
    expect(
      find.byKey(const Key('note-tag-note-work-tag-work')),
      findsOneWidget,
    );
  });
}

class _MemoryNoteRepository implements NoteRepository {
  _MemoryNoteRepository(this.items);

  final List<NoteItem> items;

  @override
  String get storagePath => '/tmp/floatick-note-panel-test/notes.json';

  @override
  Future<List<NoteItem>> load() async => List<NoteItem>.of(items);

  @override
  Future<void> save(List<NoteItem> items) async {}
}
