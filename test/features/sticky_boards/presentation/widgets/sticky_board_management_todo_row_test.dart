import 'package:floatick/features/sticky_boards/presentation/widgets/sticky_board_management_todo_row.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows read-only todo metadata and only exposes details and removal',
    (tester) async {
      var detailsCount = 0;
      var removeCount = 0;
      final item = TodoItem(
        id: 'todo-1',
        title: 'Review candidate',
        content: 'Read-only content',
        createdAt: DateTime.utc(2026, 7, 27, 2),
        completedAt: DateTime.utc(2026, 7, 27, 3),
      );
      final tag = TodoTag(
        id: 'tag-1',
        name: 'Release',
        colorValue: 0xFF20BFAF,
        createdAt: DateTime.utc(2026, 7, 27, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 380,
              child: StickyBoardManagementTodoRow(
                item: item,
                tags: <TodoTag>[tag],
                assignedTagIds: const <String>['tag-1'],
                onOpenDetails: () => detailsCount += 1,
                onRemove: () => removeCount += 1,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Review candidate'), findsOneWidget);
      expect(find.text('Release'), findsOneWidget);
      expect(
        find.byKey(const Key('sticky-board-managed-tag-todo-1-tag-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('sticky-board-managed-time-todo-1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('toggle-todo-todo-1')), findsNothing);
      expect(find.byKey(const Key('edit-todo-todo-1')), findsNothing);
      expect(find.byKey(const Key('view-todo-todo-1')), findsNothing);
      expect(find.byKey(const Key('archive-todo-todo-1')), findsNothing);
      expect(find.byKey(const Key('assign-tags-todo-1')), findsNothing);

      await tester.tap(
        find.byKey(const Key('sticky-board-managed-completion-status-todo-1')),
      );
      await tester.pump();
      expect(detailsCount, 0);
      expect(removeCount, 0);

      await tester.tap(
        find.byKey(const Key('sticky-board-managed-open-details-todo-1')),
      );
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(
        find.byKey(const Key('sticky-board-managed-open-details-todo-1')),
      );
      await tester.pumpAndSettle();
      expect(detailsCount, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(
        tester.getCenter(find.byType(StickyBoardManagementTodoRow)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('remove-from-board-todo-1')));
      await tester.pump();
      expect(removeCount, 1);
    },
  );
}
