import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

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

class StickyBoardWindowCoordinator {
  StickyBoardWindowCoordinator({
    required StickyBoardViewModel boardController,
    required TodoViewModel todoController,
  }) : _boards = boardController,
       _todos = todoController;

  static const Size defaultWindowSize = Size(380, 460);
  static const Size minimumWindowSize = Size(320, 300);
  static const Size maximumWindowSize = Size(560, 760);

  final StickyBoardViewModel _boards;
  final TodoViewModel _todos;
  final Map<String, int> _windowIdsByBoardId = <String, int>{};

  StickyBoardMainWindowRequestHandler? _mainWindowRequest;
  bool _didRestorePinnedBoards = false;

  void setMainWindowRequestHandler(
    StickyBoardMainWindowRequestHandler? handler,
  ) {
    _mainWindowRequest = handler;
  }

  void requestMainWindow(StickyBoardMainWindowRequest request) {
    _mainWindowRequest?.call(request);
  }

  Future<void> restorePinnedBoards() async {
    if (_didRestorePinnedBoards) {
      return;
    }
    _didRestorePinnedBoards = true;
    for (final board in _boards.boards.where((board) => board.isPinned)) {
      await _openWindow(board.id);
    }
  }

  Future<void> togglePin(String boardId) async {
    final board = _boards.boardById(boardId);
    if (board == null) {
      return;
    }
    if (board.isPinned) {
      await unpin(boardId);
    } else {
      await pin(boardId);
    }
  }

  Future<void> pin(String boardId) async {
    final board = _boards.boardById(boardId);
    if (board == null) {
      return;
    }
    if (!board.isPinned && !await _boards.setPinned(boardId, true)) {
      return;
    }
    try {
      await _openWindow(boardId);
    } on Object catch (error, stackTrace) {
      await _boards.setPinned(boardId, false);
      debugPrint('Floatick could not pin sticky board $boardId: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> unpin(String boardId) async {
    final viewId = _windowIdsByBoardId.remove(boardId);
    if (viewId != null) {
      try {
        final window = MultiViewDesktop.fromId(viewId);
        await window.setPreventClose(false);
        await window.closeWindow();
      } on Object catch (error, stackTrace) {
        debugPrint('Floatick could not close sticky board $boardId: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    await _boards.setPinned(boardId, false);
  }

  Future<StickyBoardMutationResult> deleteBoard(String boardId) async {
    final viewId = _windowIdsByBoardId.remove(boardId);
    if (viewId != null) {
      try {
        final window = MultiViewDesktop.fromId(viewId);
        await window.setPreventClose(false);
        await window.closeWindow();
      } on Object catch (error, stackTrace) {
        debugPrint(
          'Floatick could not close deleted sticky board $boardId: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    return _boards.deleteBoard(boardId);
  }

  void registerWindow({required String boardId, required int viewId}) {
    _windowIdsByBoardId[boardId] = viewId;
  }

  void forgetWindow(String boardId) {
    _windowIdsByBoardId.remove(boardId);
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

  Future<void> _openWindow(String boardId) async {
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
    await window.setVisibleOnAllWorkspaces(true, visibleOnFullScreen: true);
    if (frame != null) {
      await window.setPosition(Offset(frame.left, frame.top));
    }
  }
}
