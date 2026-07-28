import 'package:floatick/core/platform/window_bridge.dart';
import 'package:floatick/features/sticky_boards/data/sticky_board_repository.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board_workspace.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_view_model.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_window_coordinator.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards a typed main-window navigation request', () {
    final coordinator = StickyBoardWindowCoordinator(
      boardController: StickyBoardViewModel(
        repository: _MemoryStickyBoardRepository(),
      ),
      todoController: TodoViewModel(
        todoRepository: _MemoryTodoRepository(),
        tagRepository: _MemoryTagRepository(),
      ),
      windowBridge: _MemoryWindowBridge(),
    );
    StickyBoardMainWindowRequest? receivedRequest;
    coordinator.setMainWindowRequestHandler((request) {
      receivedRequest = request;
    });

    coordinator.requestMainWindow(
      const StickyBoardMainWindowRequest(
        boardId: 'board-1',
        destination: StickyBoardMainWindowDestination.todoEdit,
        todoId: 'todo-1',
      ),
    );

    expect(receivedRequest?.boardId, 'board-1');
    expect(
      receivedRequest?.destination,
      StickyBoardMainWindowDestination.todoEdit,
    );
    expect(receivedRequest?.todoId, 'todo-1');
  });

  test('continues restoring boards and retries only failed windows', () async {
    final boardController = StickyBoardViewModel(
      repository: _MemoryStickyBoardRepository(
        workspace: StickyBoardWorkspace(
          boards: <StickyBoard>[
            StickyBoard(
              id: 'board-retry',
              name: 'Retry',
              colorValue: 0xFF20B8A8,
              createdAt: DateTime.utc(2026, 7, 27),
              isPinned: true,
            ),
            StickyBoard(
              id: 'board-ready',
              name: 'Ready',
              colorValue: 0xFF4C8FF5,
              createdAt: DateTime.utc(2026, 7, 27),
              isPinned: true,
            ),
          ],
          boardTodoIds: const <String, List<String>>{},
        ),
      ),
    );
    await boardController.load();
    final launchCounts = <String, int>{};
    final coordinator = StickyBoardWindowCoordinator(
      boardController: boardController,
      todoController: TodoViewModel(
        todoRepository: _MemoryTodoRepository(),
        tagRepository: _MemoryTagRepository(),
      ),
      windowBridge: _MemoryWindowBridge(),
      windowLauncher: (boardId) async {
        final attempt = (launchCounts[boardId] ?? 0) + 1;
        launchCounts[boardId] = attempt;
        if (boardId == 'board-retry' && attempt == 1) {
          throw StateError('first launch failed');
        }
      },
    );

    await coordinator.restorePinnedBoards();
    expect(launchCounts, <String, int>{'board-retry': 1, 'board-ready': 1});

    await coordinator.restorePinnedBoards();
    expect(launchCounts, <String, int>{'board-retry': 2, 'board-ready': 1});

    await coordinator.restorePinnedBoards();
    expect(launchCounts, <String, int>{'board-retry': 2, 'board-ready': 1});
  });

  test('does not persist pinned state when the window cannot open', () async {
    final boardController = StickyBoardViewModel(
      repository: _MemoryStickyBoardRepository(
        workspace: StickyBoardWorkspace(
          boards: <StickyBoard>[
            StickyBoard(
              id: 'board-failed',
              name: 'Failed',
              colorValue: 0xFF20B8A8,
              createdAt: DateTime.utc(2026, 7, 27),
            ),
          ],
          boardTodoIds: const <String, List<String>>{},
        ),
      ),
    );
    await boardController.load();
    final coordinator = StickyBoardWindowCoordinator(
      boardController: boardController,
      todoController: TodoViewModel(
        todoRepository: _MemoryTodoRepository(),
        tagRepository: _MemoryTagRepository(),
      ),
      windowBridge: _MemoryWindowBridge(),
      windowLauncher: (_) => throw StateError('window unavailable'),
    );

    await coordinator.pin('board-failed');

    expect(boardController.boardById('board-failed')?.isPinned, isFalse);
  });

  test('a pinned board can always be toggled back to unpinned', () async {
    final boardController = StickyBoardViewModel(
      repository: _MemoryStickyBoardRepository(
        workspace: StickyBoardWorkspace(
          boards: <StickyBoard>[
            StickyBoard(
              id: 'board-toggle',
              name: 'Toggle',
              colorValue: 0xFF20B8A8,
              createdAt: DateTime.utc(2026, 7, 27),
            ),
          ],
          boardTodoIds: const <String, List<String>>{},
        ),
      ),
    );
    final hiddenBoardIds = <String>[];
    await boardController.load();
    final coordinator = StickyBoardWindowCoordinator(
      boardController: boardController,
      todoController: TodoViewModel(
        todoRepository: _MemoryTodoRepository(),
        tagRepository: _MemoryTagRepository(),
      ),
      windowBridge: _MemoryWindowBridge(),
      windowLauncher: (_) async {},
      windowHider: (boardId) async => hiddenBoardIds.add(boardId),
    );

    await coordinator.togglePin('board-toggle');
    expect(boardController.boardById('board-toggle')?.isPinned, isTrue);

    await coordinator.togglePin('board-toggle');
    expect(boardController.boardById('board-toggle')?.isPinned, isFalse);
    expect(hiddenBoardIds, <String>['board-toggle']);

    await coordinator.togglePin('board-toggle');
    expect(boardController.boardById('board-toggle')?.isPinned, isTrue);

    await coordinator.togglePin('board-toggle');
    expect(boardController.boardById('board-toggle')?.isPinned, isFalse);
    expect(hiddenBoardIds, <String>['board-toggle', 'board-toggle']);
  });

  test('restores pinned state when hiding the board window fails', () async {
    final boardController = StickyBoardViewModel(
      repository: _MemoryStickyBoardRepository(
        workspace: StickyBoardWorkspace(
          boards: <StickyBoard>[
            StickyBoard(
              id: 'board-hide-failure',
              name: 'Hide failure',
              colorValue: 0xFF20B8A8,
              createdAt: DateTime.utc(2026, 7, 27),
              isPinned: true,
            ),
          ],
          boardTodoIds: const <String, List<String>>{},
        ),
      ),
    );
    await boardController.load();
    final coordinator = StickyBoardWindowCoordinator(
      boardController: boardController,
      todoController: TodoViewModel(
        todoRepository: _MemoryTodoRepository(),
        tagRepository: _MemoryTagRepository(),
      ),
      windowBridge: _MemoryWindowBridge(),
      windowHider: (_) => throw StateError('window unavailable'),
    );

    await coordinator.unpin('board-hide-failure');

    expect(boardController.boardById('board-hide-failure')?.isPinned, isTrue);
  });
}

class _MemoryWindowBridge implements WindowBridge {
  @override
  Future<void> configureBorderlessSecondaryWindow(
    int viewId, {
    bool positionAdjacentToMainWindow = false,
  }) async {}

  @override
  Future<void> revealBorderlessSecondaryWindow(int viewId) async {}

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    return WindowExpansionAnchor.topRight;
  }

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {}

  @override
  Future<void> setExpanded(bool expanded, {bool animated = true}) async {}

  @override
  Future<void> setFloatingIconCount(int activeCount) async {}

  @override
  Future<void> setPreferredLanguage(String? languageCode) async {}

  @override
  Future<void> setPreferredTheme(String themePreference) async {}

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {}
}

class _MemoryStickyBoardRepository implements StickyBoardRepository {
  _MemoryStickyBoardRepository({StickyBoardWorkspace? workspace})
    : _workspace = workspace ?? StickyBoardWorkspace.empty();

  final StickyBoardWorkspace _workspace;

  @override
  String get storagePath => '/tmp/floatick-sticky-board-coordinator-test.json';

  @override
  Future<StickyBoardWorkspace> load() async => _workspace;

  @override
  Future<void> save(StickyBoardWorkspace workspace) async {}
}

class _MemoryTodoRepository implements TodoRepository {
  @override
  String get storagePath => '/tmp/floatick-sticky-board-todos-test.json';

  @override
  Future<List<TodoItem>> load() async => const <TodoItem>[];

  @override
  Future<void> save(List<TodoItem> items) async {}
}

class _MemoryTagRepository implements TagRepository {
  @override
  String get storagePath => '/tmp/floatick-sticky-board-tags-test.json';

  @override
  Future<TagWorkspace> load() async => TagWorkspace.empty();

  @override
  Future<void> save(TagWorkspace workspace) async {}
}
