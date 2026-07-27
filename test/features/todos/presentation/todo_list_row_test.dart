import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/features/todos/presentation/widgets/todo_list_row.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('external tag action bypasses the inline assignment menu', (
    tester,
  ) async {
    var openCount = 0;
    final item = TodoItem(
      id: 'todo-1',
      title: 'Review the draft',
      createdAt: DateTime.utc(2026, 7, 27, 8),
    );
    final tags = <TodoTag>[
      TodoTag(
        id: 'tag-1',
        name: 'Work',
        colorValue: 0xFF20BFB2,
        createdAt: DateTime.utc(2026, 7, 27, 7),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TodoListRow(
            item: item,
            archivedScope: false,
            onToggle: () {},
            onOpenDetails: () {},
            onEdit: () {},
            onArchive: () {},
            onRestore: () {},
            tags: tags,
            assignedTagIds: const <String>['tag-1'],
            onOpenTagAssignment: () => openCount += 1,
            showArchiveAction: false,
          ),
        ),
      ),
    );

    expect(find.text('Work'), findsOneWidget);
    expect(find.byType(MenuAnchor), findsNothing);
    expect(find.byIcon(Icons.archive_outlined), findsNothing);

    await tester.tap(find.byKey(const Key('assign-tags-todo-1')));

    expect(openCount, 1);
  });
}
