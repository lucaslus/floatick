import 'package:flutter/material.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

import '../../../core/platform/window_bridge.dart';
import '../../todos/presentation/todo_view_model.dart';
import '../domain/sticky_board.dart';
import 'pinned_sticky_board_window.dart';
import 'sticky_board_view_model.dart';

enum StickyBoardMainWindowDestination { board, todoDetails, todoEdit }

class StickyBoardMainWindowRequest {
  const StickyBoardMainWindowRequest({
    required this.boardId,
    this.destination = StickyBoardMainWindowDestination.board,
    this.todoId,
  }) : assert(
         destination == StickyBoardMainWindowDestination.board ||
             todoId != null,
       );

  final String boardId;
  final StickyBoardMainWindowDestination destination;
  final String? todoId;
}

typedef StickyBoardMainWindowRequestHandler =
    void Function(StickyBoardMainWindowRequest request);
typedef StickyBoardWindowLauncher = Future<void> Function(String boardId);
typedef StickyBoardWindowHider = Future<void> Function(String boardId);

class StickyBoardWindowCoordinator {
  StickyBoardWindowCoordinator({
    required StickyBoardViewModel boardController,
    required TodoViewModel todoController,
    required this.windowBridge,
    this.windowLauncher,
    this.windowHider,
  }) : _boards = boardController,
       _todos = todoController;

  static const Size defaultWindowSize = Size(380, 460);
  static const Size minimumWindowSize = Size(320, 300);
  static const Size maximumWindowSize = Size(560, 760);

  final StickyBoardViewModel _boards;
  final TodoViewModel _todos;
  final WindowBridge windowBridge;
  final StickyBoardWindowLauncher? windowLauncher;
  final StickyBoardWindowHider? windowHider;
  final Map<String, int> _windowIdsByBoardId = <String, int>{};
  final Map<String, Future<void>> _boardWindowOperations =
      <String, Future<void>>{};
  final Set<String> _restoredPinnedBoardIds = <String>{};

  StickyBoardMainWindowRequestHandler? _mainWindowRequest;
  bool _didRestorePinnedBoards = false;
  Future<void>? _restorePinnedBoardsOperation;

  void setMainWindowRequestHandler(
    StickyBoardMainWindowRequestHandler? handler,
  ) {
    _mainWindowRequest = handler;
  }

  void requestMainWindow(StickyBoardMainWindowRequest request) {
    _mainWindowRequest?.call(request);
  }

  Future<void> restorePinnedBoards() {
    if (_didRestorePinnedBoards) {
      return Future<void>.value();
    }
    return _restorePinnedBoardsOperation ??= _restorePinnedBoards()
        .whenComplete(() => _restorePinnedBoardsOperation = null);
  }

  Future<void> _restorePinnedBoards() async {
    final pinnedBoardIds = _boards.boards
        .where((board) => board.isPinned)
        .map((board) => board.id)
        .toSet();
    _restoredPinnedBoardIds.removeWhere(
      (boardId) => !pinnedBoardIds.contains(boardId),
    );
    var hadFailure = false;
    for (final boardId in pinnedBoardIds.where(
      (boardId) => !_restoredPinnedBoardIds.contains(boardId),
    )) {
      try {
        await _openWindow(boardId);
        _restoredPinnedBoardIds.add(boardId);
      } on Object catch (error, stackTrace) {
        await _hideRegisteredWindowBestEffort(boardId);
        hadFailure = true;
        debugPrint('Floatick could not restore sticky board $boardId: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    _didRestorePinnedBoards =
        !hadFailure && _restoredPinnedBoardIds.containsAll(pinnedBoardIds);
  }

  Future<void> togglePin(String boardId) {
    return _enqueueBoardWindowOperation(boardId, () async {
      final board = _boards.boardById(boardId);
      if (board == null) {
        return;
      }
      if (board.isPinned) {
        await _unpin(boardId);
      } else {
        await _pin(boardId);
      }
    });
  }

  Future<void> pin(String boardId) {
    return _enqueueBoardWindowOperation(boardId, () => _pin(boardId));
  }

  Future<void> unpin(String boardId) {
    return _enqueueBoardWindowOperation(boardId, () => _unpin(boardId));
  }

  Future<void> _pin(String boardId) async {
    final board = _boards.boardById(boardId);
    if (board == null) {
      return;
    }
    try {
      await _openWindow(boardId, positionAdjacentToMainWindow: true);
      if (!board.isPinned && !await _boards.setPinned(boardId, true)) {
        await _hideRegisteredWindowBestEffort(boardId);
        return;
      }
      _restoredPinnedBoardIds.add(boardId);
    } on Object catch (error, stackTrace) {
      await _hideRegisteredWindowBestEffort(boardId);
      debugPrint('Floatick could not pin sticky board $boardId: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _unpin(String boardId) async {
    _restoredPinnedBoardIds.remove(boardId);
    _didRestorePinnedBoards = false;
    if (!await _boards.setPinned(boardId, false)) {
      return;
    }
    try {
      await _hideRegisteredWindow(boardId);
    } on Object catch (error, stackTrace) {
      final restored = await _boards.setPinned(boardId, true);
      if (restored) {
        _restoredPinnedBoardIds.add(boardId);
      } else {
        debugPrint(
          'Floatick could not restore the pin state for sticky board $boardId.',
        );
      }
      debugPrint('Floatick could not unpin sticky board $boardId: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<StickyBoardMutationResult> deleteBoard(String boardId) async {
    _restoredPinnedBoardIds.remove(boardId);
    _didRestorePinnedBoards = false;
    final result = await _boards.deleteBoard(boardId);
    if (result == StickyBoardMutationResult.success) {
      await _hideRegisteredWindowBestEffort(boardId);
    }
    return result;
  }

  void registerWindow({required String boardId, required int viewId}) {
    _windowIdsByBoardId[boardId] = viewId;
  }

  void forgetWindow({required String boardId, required int viewId}) {
    if (_windowIdsByBoardId[boardId] == viewId) {
      _windowIdsByBoardId.remove(boardId);
    }
  }

  Future<void> saveWindowFrame({
    required String boardId,
    required Rect bounds,
  }) {
    return _boards
        .saveWindowFrame(
          boardId: boardId,
          frame: StickyBoardWindowFrame(
            left: bounds.left,
            top: bounds.top,
            width: bounds.width,
            height: bounds.height,
          ),
        )
        .then<void>((_) {});
  }

  Future<void> _openWindow(
    String boardId, {
    bool positionAdjacentToMainWindow = false,
  }) async {
    final launcher = windowLauncher;
    if (launcher != null) {
      await launcher(boardId);
      return;
    }
    final existingViewId = _windowIdsByBoardId[boardId];
    if (existingViewId != null) {
      await MultiViewDesktop.fromId(existingViewId).show();
      await MultiViewDesktop.fromId(existingViewId).focus();
      return;
    }
    final board = _boards.boardById(boardId);
    if (board == null) {
      return;
    }
    final frame = board.windowFrame;
    final shouldPositionAdjacent =
        positionAdjacentToMainWindow || frame == null;
    final viewId = await openWindow(
      (context, id) => PinnedStickyBoardWindow(
        boardId: boardId,
        viewId: id,
        boardController: _boards,
        todoController: _todos,
        coordinator: this,
      ),
      options: WindowOptions(
        size: frame == null
            ? defaultWindowSize
            : Size(frame.width, frame.height),
        minimumSize: minimumWindowSize,
        maximumSize: maximumWindowSize,
        alignment: Alignment.center,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
        title: board.name,
        alwaysOnTop: true,
      ),
    );
    _windowIdsByBoardId[boardId] = viewId;
    final window = MultiViewDesktop.fromId(viewId);
    await window.setHasShadow(false);
    await windowBridge.configureBorderlessSecondaryWindow(
      viewId,
      positionAdjacentToMainWindow: shouldPositionAdjacent,
    );
    await window.setVisibleOnAllWorkspaces(true, visibleOnFullScreen: true);
    if (frame != null && !shouldPositionAdjacent) {
      await window.setPosition(Offset(frame.left, frame.top));
    }
  }

  Future<void> _enqueueBoardWindowOperation(
    String boardId,
    Future<void> Function() operation,
  ) {
    final previousOperation =
        _boardWindowOperations[boardId] ?? Future<void>.value();
    final nextOperation = previousOperation.then<void>(
      (_) => operation(),
      onError: (Object _, StackTrace _) => operation(),
    );
    _boardWindowOperations[boardId] = nextOperation;
    return nextOperation.whenComplete(() {
      if (identical(_boardWindowOperations[boardId], nextOperation)) {
        _boardWindowOperations.remove(boardId);
      }
    });
  }

  Future<void> _hideRegisteredWindow(String boardId) async {
    final hider = windowHider;
    if (hider != null) {
      await hider(boardId);
      return;
    }
    final viewId = _windowIdsByBoardId[boardId];
    if (viewId != null) {
      await MultiViewDesktop.fromId(viewId).hide();
    }
  }

  Future<void> _hideRegisteredWindowBestEffort(String boardId) async {
    try {
      await _hideRegisteredWindow(boardId);
    } on Object catch (error, stackTrace) {
      debugPrint('Floatick could not hide sticky board $boardId: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
