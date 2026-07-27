import 'package:floatick/core/platform/window_bridge.dart';
import 'package:floatick/features/sticky_boards/data/sticky_board_repository.dart';
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
}

class _MemoryWindowBridge implements WindowBridge {
  @override
  Future<void> configureBorderlessSecondaryWindow(int viewId) async {}

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    return WindowExpansionAnchor.topRight;
  }

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {}

  @override
  Future<void> setExpanded(bool expanded) async {}

  @override
  Future<void> setPreferredLanguage(String? languageCode) async {}

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {}
}

class _MemoryStickyBoardRepository implements StickyBoardRepository {
  @override
  String get storagePath => '/tmp/floatick-sticky-board-coordinator-test.json';

  @override
  Future<StickyBoardWorkspace> load() async => StickyBoardWorkspace.empty();

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
