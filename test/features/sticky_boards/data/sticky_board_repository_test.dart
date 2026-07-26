import 'dart:io';

import 'package:floatick/features/sticky_boards/data/sticky_board_repository.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local repository creates storage and persists a workspace', () async {
    final root = await Directory.systemTemp.createTemp(
      'floatick-sticky-boards-',
    );
    addTearDown(() => root.delete(recursive: true));
    final repository = LocalStickyBoardRepository(rootDirectory: root);
    final workspace = StickyBoardWorkspace(
      boards: <StickyBoard>[
        StickyBoard(
          id: 'board-1',
          name: 'This week',
          colorValue: 0xFF4C8FF5,
          createdAt: DateTime.utc(2026, 7, 26),
        ),
      ],
      boardTodoIds: const <String, List<String>>{
        'board-1': <String>['todo-1'],
      },
    );

    await repository.save(workspace);

    expect(await repository.load(), isNot(same(workspace)));
    expect((await repository.load()).boards, workspace.boards);
    expect((await repository.load()).todoIdsForBoard('board-1'), <String>[
      'todo-1',
    ]);
    expect(await File(repository.storagePath).exists(), isTrue);
  });
}
