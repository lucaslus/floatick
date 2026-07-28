import 'package:floatick/features/sticky_boards/data/sticky_board_repository.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board_workspace.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CRUD keeps todos independent and supports many-to-many membership',
    () async {
      var idSequence = 0;
      final repository = _MemoryStickyBoardRepository();
      final controller = StickyBoardViewModel(
        repository: repository,
        clock: () => DateTime.utc(2026, 7, 26),
        idGenerator: () => 'board-${++idSequence}',
      );
      await controller.load();

      expect(
        await controller.createBoard(name: ' Work ', colorValue: 0xFF20B8A8),
        StickyBoardMutationResult.success,
      );
      expect(
        await controller.createBoard(name: 'work', colorValue: 0xFF4C8FF5),
        StickyBoardMutationResult.duplicateName,
      );
      expect(
        await controller.createBoard(name: 'Personal', colorValue: 0xFF4C8FF5),
        StickyBoardMutationResult.success,
      );

      await controller.addTodo(boardId: 'board-1', todoId: 'todo-1');
      await controller.addTodo(boardId: 'board-2', todoId: 'todo-1');
      await controller.addTodo(boardId: 'board-1', todoId: 'todo-2');

      expect(controller.todoIdsForBoard('board-1'), <String>[
        'todo-1',
        'todo-2',
      ]);
      expect(controller.todoIdsForBoard('board-2'), <String>['todo-1']);

      await controller.deleteBoard('board-1');

      expect(controller.boardById('board-1'), isNull);
      expect(controller.todoIdsForBoard('board-2'), <String>['todo-1']);
      expect(repository.savedWorkspace.boardTodoIds, <String, List<String>>{
        'board-2': <String>['todo-1'],
      });
    },
  );

  test(
    'pin state and window frame persist without changing relations',
    () async {
      final repository = _MemoryStickyBoardRepository();
      final controller = StickyBoardViewModel(
        repository: repository,
        idGenerator: () => 'board-1',
      );
      await controller.load();
      await controller.createBoard(name: 'Today', colorValue: 0xFF20B8A8);
      await controller.addTodo(boardId: 'board-1', todoId: 'todo-1');

      expect(await controller.setPinned('board-1', true), isTrue);
      expect(
        await controller.saveWindowFrame(
          boardId: 'board-1',
          frame: const StickyBoardWindowFrame(
            left: 10,
            top: 20,
            width: 380,
            height: 460,
          ),
        ),
        isTrue,
      );

      final board = controller.boardById('board-1');
      expect(board?.isPinned, isTrue);
      expect(board?.windowFrame?.left, 10);
      expect(controller.todoIdsForBoard('board-1'), <String>['todo-1']);
    },
  );

  test('removing a deleted todo cleans every board relation', () async {
    var idSequence = 0;
    final repository = _MemoryStickyBoardRepository();
    final controller = StickyBoardViewModel(
      repository: repository,
      idGenerator: () => 'board-${++idSequence}',
    );
    await controller.load();
    await controller.createBoard(name: 'Work', colorValue: 0xFF20B8A8);
    await controller.createBoard(name: 'Later', colorValue: 0xFF4C8FF5);
    await controller.addTodo(boardId: 'board-1', todoId: 'todo-1');
    await controller.addTodo(boardId: 'board-1', todoId: 'todo-2');
    await controller.addTodo(boardId: 'board-2', todoId: 'todo-1');

    expect(await controller.removeTodoFromAllBoards('todo-1'), isTrue);

    expect(controller.todoIdsForBoard('board-1'), <String>['todo-2']);
    expect(controller.todoIdsForBoard('board-2'), isEmpty);
    expect(controller.boards.length, 2);
    expect(repository.savedWorkspace.boardTodoIds, <String, List<String>>{
      'board-1': <String>['todo-2'],
    });
  });
}

class _MemoryStickyBoardRepository implements StickyBoardRepository {
  StickyBoardWorkspace savedWorkspace = StickyBoardWorkspace.empty();

  @override
  String get storagePath => '/tmp/floatick-test/sticky_boards.json';

  @override
  Future<StickyBoardWorkspace> load() async => savedWorkspace;

  @override
  Future<void> save(StickyBoardWorkspace workspace) async {
    savedWorkspace = workspace;
  }
}
