import 'package:floatick/features/notes/data/note_repository.dart';
import 'package:floatick/features/notes/domain/note_item.dart';
import 'package:floatick/features/notes/presentation/note_panel_content.dart';
import 'package:floatick/features/notes/presentation/note_view_model.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('note list groups active notes by their last edited date', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final olderDay = today.subtract(const Duration(days: 3));
    final controller = NoteViewModel(
      repository: _MemoryNoteRepository(<NoteItem>[
        _note(id: 'today-new', day: today, hour: 15),
        _note(id: 'today-old', day: today, hour: 9),
        _note(id: 'previous-day', day: yesterday, hour: 16),
        _note(id: 'older', day: olderDay, hour: 12),
      ]),
    );
    await controller.load();

    await tester.pumpWidget(
      _NotePanelTestApp(controller: controller, archived: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    final context = tester.element(find.byType(NotePanelContent));
    expect(
      find.text(MaterialLocalizations.of(context).formatFullDate(olderDay)),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Today New')).dy,
      lessThan(tester.getTopLeft(find.text('Today Old')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Today Old')).dy,
      lessThan(tester.getTopLeft(find.text('Previous Day')).dy),
    );
  });

  testWidgets('archived notes are grouped by archive date', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final editedDay = today.subtract(const Duration(days: 10));
    final controller = NoteViewModel(
      repository: _MemoryNoteRepository(<NoteItem>[
        _note(
          id: 'archived-today',
          day: editedDay,
          hour: 8,
          archivedAt: today.add(const Duration(hours: 14)),
        ),
        _note(
          id: 'archived-yesterday',
          day: editedDay,
          hour: 9,
          archivedAt: yesterday.add(const Duration(hours: 11)),
        ),
      ]),
    );
    await controller.load();

    await tester.pumpWidget(
      _NotePanelTestApp(controller: controller, archived: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Archived Today'), findsOneWidget);
    expect(find.text('Archived Yesterday'), findsOneWidget);
  });

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

NoteItem _note({
  required String id,
  required DateTime day,
  required int hour,
  DateTime? archivedAt,
}) {
  final timestamp = DateTime(day.year, day.month, day.day, hour);
  return NoteItem(
    id: id,
    title: id
        .split('-')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' '),
    content: '',
    createdAt: timestamp,
    updatedAt: timestamp,
    archivedAt: archivedAt,
  );
}

class _NotePanelTestApp extends StatelessWidget {
  const _NotePanelTestApp({required this.controller, required this.archived});

  final NoteViewModel controller;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 440,
          height: 600,
          child: NotePanelContent(
            controller: controller,
            archived: archived,
            query: '',
            availableTags: const <TodoTag>[],
            selectedTagIds: const <String>{},
            onOpen: (_) {},
          ),
        ),
      ),
    );
  }
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
