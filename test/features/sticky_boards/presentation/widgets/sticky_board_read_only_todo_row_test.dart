import 'package:floatick/features/sticky_boards/presentation/widgets/sticky_board_read_only_todo_row.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toggles completion and opens local details on double tap', (
    tester,
  ) async {
    var detailsCount = 0;
    var completionToggleCount = 0;
    final item = TodoItem(
      id: 'todo-1',
      title: 'Review candidate',
      content: 'Read-only content',
      createdAt: DateTime.utc(2026, 7, 27, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 380,
            child: StickyBoardReadOnlyTodoRow(
              item: item,
              onToggleCompletion: () => completionToggleCount += 1,
              onOpenDetails: () => detailsCount += 1,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Review candidate'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byKey(const Key('assign-tags-todo-1')), findsNothing);
    expect(find.byKey(const Key('edit-todo-todo-1')), findsNothing);
    expect(
      find.byKey(const Key('sticky-board-todo-time-todo-1')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('sticky-board-todo-tag-todo-1-tag-1')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('sticky-board-completion-toggle-todo-1')),
    );
    await tester.pump();

    expect(completionToggleCount, 1);
    expect(detailsCount, 0);

    await tester.tap(
      find.byKey(const Key('sticky-board-open-details-region-todo-1')),
    );
    await tester.pump(kDoubleTapTimeout);
    expect(detailsCount, 0);

    await tester.tap(
      find.byKey(const Key('sticky-board-open-details-region-todo-1')),
    );
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(
      find.byKey(const Key('sticky-board-open-details-region-todo-1')),
    );
    await tester.pumpAndSettle();

    expect(detailsCount, 1);
  });
}
