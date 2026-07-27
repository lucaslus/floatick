import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/features/todos/presentation/widgets/todo_list_row.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'primary controls align and double-clicking the title opens details',
    (tester) async {
      var toggleCount = 0;
      var detailsCount = 0;
      final item = TodoItem(
        id: 'aligned',
        title: 'Review the aligned row',
        createdAt: DateTime.utc(2026, 7, 27, 8),
      );
      final tags = <TodoTag>[
        TodoTag(
          id: 'tag-work',
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
            body: Center(
              child: SizedBox(
                width: 420,
                child: TodoListRow(
                  item: item,
                  archivedScope: false,
                  onToggle: () => toggleCount += 1,
                  onOpenDetails: () => detailsCount += 1,
                  onEdit: () {},
                  onArchive: () {},
                  onRestore: () {},
                  tags: tags,
                  assignedTagIds: const <String>['tag-work'],
                  onOpenTagAssignment: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final primaryCenterY = tester
          .getCenter(find.byKey(const Key('todo-title-aligned')))
          .dy;
      for (final key in <String>[
        'toggle-todo-aligned',
        'edit-todo-aligned',
        'view-todo-aligned',
        'archive-todo-aligned',
      ]) {
        expect(
          tester.getCenter(find.byKey(Key(key))).dy,
          closeTo(primaryCenterY, 0.5),
        );
      }

      final tagCenterY = tester
          .getCenter(find.byKey(const Key('todo-tag-aligned-tag-work')))
          .dy;
      final timeCenterY = tester
          .getCenter(find.byKey(const Key('todo-time-aligned')))
          .dy;
      expect(timeCenterY, closeTo(tagCenterY, 0.5));
      expect(tagCenterY, greaterThan(primaryCenterY + 10));

      final detailsRegion = find.byKey(
        const Key('todo-open-details-region-aligned'),
      );
      await tester.tap(detailsRegion);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(detailsRegion);
      await tester.pump();

      expect(detailsCount, 1);

      await tester.tap(find.byKey(const Key('toggle-todo-aligned')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(toggleCount, 1);
      expect(detailsCount, 1);
    },
  );

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

  testWidgets(
    'inline tag action opens a responsive bottom sheet and reflects saved state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var saveSucceeds = false;
      var toggleCount = 0;
      var manageCount = 0;
      final item = TodoItem(
        id: 'bottom-sheet',
        title: 'Plan mobile tag flow',
        createdAt: DateTime.utc(2026, 7, 27, 8),
      );
      final tags = <TodoTag>[
        TodoTag(
          id: 'tag-work',
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
              assignedTagIds: const <String>[],
              onToggleTag: (_) async {
                toggleCount += 1;
                return saveSucceeds;
              },
              onOpenTagManagement: () => manageCount += 1,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('assign-tags-bottom-sheet')));
      await tester.pumpAndSettle();

      final sheet = find.byKey(const Key('tag-assignment-bottom-sheet'));
      final tagRow = find.byKey(const Key('assign-bottom-sheet-tag-work'));
      expect(sheet, findsOneWidget);
      expect(find.byType(MenuAnchor), findsNothing);
      expect(tester.getSize(sheet).width, closeTo(390, 0.5));
      expect(tester.getSize(sheet).height, lessThanOrEqualTo(844 * 0.72));
      expect(tester.getSize(tagRow).height, greaterThanOrEqualTo(44));

      await tester.tap(tagRow);
      await tester.pumpAndSettle();
      expect(toggleCount, 1);
      expect(
        find.descendant(of: tagRow, matching: find.byIcon(Icons.check_rounded)),
        findsNothing,
      );

      saveSucceeds = true;
      await tester.tap(tagRow);
      await tester.pumpAndSettle();
      expect(toggleCount, 2);
      expect(
        find.descendant(of: tagRow, matching: find.byIcon(Icons.check_rounded)),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('tag-assignment-manage')));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(manageCount, 1);
    },
  );

  testWidgets(
    'archived row only offers view, restore, and confirmed deletion',
    (tester) async {
      var viewCount = 0;
      var restoreCount = 0;
      var deleteCount = 0;
      final item = TodoItem(
        id: 'archived',
        title: 'Archived todo',
        createdAt: DateTime.utc(2026, 7, 27, 8),
        archivedAt: DateTime.utc(2026, 7, 27, 9),
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
              archivedScope: true,
              onToggle: () {},
              onOpenDetails: () => viewCount += 1,
              onEdit: null,
              onArchive: () {},
              onRestore: () => restoreCount += 1,
              tags: tags,
              assignedTagIds: const <String>['tag-1'],
              onDeletePermanently: () => deleteCount += 1,
            ),
          ),
        ),
      );

      expect(find.text('Work'), findsOneWidget);
      expect(find.byKey(const Key('edit-todo-archived')), findsNothing);
      expect(find.byKey(const Key('assign-tags-archived')), findsNothing);

      await tester.tap(find.byKey(const Key('view-todo-archived')));
      await tester.tap(find.byKey(const Key('restore-todo-archived')));
      expect(viewCount, 1);
      expect(restoreCount, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(find.byType(TodoListRow)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-todo-archived')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cancel-delete-todo-archived')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('confirm-delete-todo-archived')),
        findsOneWidget,
      );
      expect(deleteCount, 0);

      await tester.tap(find.byKey(const Key('confirm-delete-todo-archived')));
      expect(deleteCount, 1);
    },
  );
}
