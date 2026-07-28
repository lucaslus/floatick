import 'package:floatick/features/sticky_boards/presentation/widgets/sticky_board_todo_details.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows todo content locally without edit actions', (
    tester,
  ) async {
    var backCount = 0;
    final item = TodoItem(
      id: 'todo-1',
      title: 'Prepare release',
      content: '## Checklist\n\n- Verify the DMG',
      createdAt: DateTime.utc(2026, 7, 27, 2),
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
            height: 460,
            child: StickyBoardTodoDetails(
              item: item,
              tags: <TodoTag>[tag],
              onBack: () => backCount += 1,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('sticky-board-details-title')), findsOneWidget);
    expect(find.text('Prepare release'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('Verify the DMG'), findsOneWidget);
    expect(find.text('Release'), findsOneWidget);
    expect(find.byKey(const Key('sticky-board-details-edit')), findsNothing);

    await tester.tap(find.byKey(const Key('sticky-board-details-back')));

    expect(backCount, 1);
  });
}
