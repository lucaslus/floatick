import 'package:floatick/features/sticky_boards/domain/sticky_board.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workspace round-trips boards, ordered todo relations, and frame', () {
    final workspace = StickyBoardWorkspace(
      boards: <StickyBoard>[
        StickyBoard(
          id: 'board-1',
          name: 'Launch',
          colorValue: 0xFF20B8A8,
          createdAt: DateTime.utc(2026, 7, 26),
          isPinned: true,
          windowFrame: const StickyBoardWindowFrame(
            left: 120,
            top: 80,
            width: 380,
            height: 460,
          ),
        ),
      ],
      boardTodoIds: const <String, List<String>>{
        'board-1': <String>['todo-2', 'todo-1'],
      },
    );

    final restored = StickyBoardWorkspace.fromJson(workspace.toJson());

    expect(restored.boards, workspace.boards);
    expect(restored.todoIdsForBoard('board-1'), <String>['todo-2', 'todo-1']);
  });

  test('workspace rejects relations that reference an unknown board', () {
    expect(
      () => StickyBoardWorkspace.fromJson(<String, dynamic>{
        'version': 1,
        'boards': <Object>[],
        'boardTodoIds': <String, Object>{
          'missing-board': <String>['todo-1'],
        },
      }),
      throwsFormatException,
    );
  });
}
