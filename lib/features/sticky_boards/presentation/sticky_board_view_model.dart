import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/storage_failure.dart';
import '../data/sticky_board_repository.dart';
import '../domain/sticky_board.dart';
import '../domain/sticky_board_workspace.dart';

typedef StickyBoardClock = DateTime Function();
typedef StickyBoardIdGenerator = String Function();

enum StickyBoardMutationResult {
  success,
  emptyName,
  nameTooLong,
  duplicateName,
  notFound,
  invalidColor,
  storageFailure,
}

class StickyBoardViewModel extends ChangeNotifier {
  StickyBoardViewModel({
    required StickyBoardRepository repository,
    StickyBoardClock? clock,
    StickyBoardIdGenerator? idGenerator,
  }) : _storage = repository,
       _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateUuidV4;

  final StickyBoardRepository _storage;
  final StickyBoardClock _clock;
  final StickyBoardIdGenerator _idGenerator;

  StickyBoardWorkspace _workspace = StickyBoardWorkspace.empty();
  StorageFailure? _error;
  bool _isLoading = false;
  Future<void> _mutationQueue = Future<void>.value();

  List<StickyBoard> get boards => _workspace.boards;
  StorageFailure? get error => _error;
  bool get isLoading => _isLoading;

  StickyBoard? boardById(String id) {
    for (final board in _workspace.boards) {
      if (board.id == id) {
        return board;
      }
    }
    return null;
  }

  List<String> todoIdsForBoard(String boardId) {
    return _workspace.todoIdsForBoard(boardId);
  }

  int todoCountForBoard(String boardId) {
    return todoIdsForBoard(boardId).length;
  }

  bool containsTodo({required String boardId, required String todoId}) {
    return todoIdsForBoard(boardId).contains(todoId);
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _workspace = await _storage.load();
    } on StorageFailure catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StickyBoardMutationResult> createBoard({
    required String name,
    required int colorValue,
  }) {
    return _enqueueMutation(() async {
      final validation = _validateName(name);
      if (validation != StickyBoardMutationResult.success) {
        return validation;
      }
      if (!_isValidColorValue(colorValue)) {
        return StickyBoardMutationResult.invalidColor;
      }

      final normalizedName = name.trim();
      if (_workspace.boards.any(
        (board) => _sameName(board.name, normalizedName),
      )) {
        return StickyBoardMutationResult.duplicateName;
      }

      final boardId = _idGenerator();
      if (_workspace.boards.any((board) => board.id == boardId)) {
        return StickyBoardMutationResult.storageFailure;
      }
      final updatedWorkspace = StickyBoardWorkspace(
        boards: <StickyBoard>[
          ..._workspace.boards,
          StickyBoard(
            id: boardId,
            name: normalizedName,
            colorValue: colorValue,
            createdAt: _clock().toUtc(),
          ),
        ],
        boardTodoIds: _workspace.boardTodoIds,
      );
      return await _save(updatedWorkspace)
          ? StickyBoardMutationResult.success
          : StickyBoardMutationResult.storageFailure;
    });
  }

  Future<StickyBoardMutationResult> updateBoard({
    required String id,
    required String name,
    required int colorValue,
  }) {
    return _enqueueMutation(() async {
      final validation = _validateName(name);
      if (validation != StickyBoardMutationResult.success) {
        return validation;
      }
      if (!_isValidColorValue(colorValue)) {
        return StickyBoardMutationResult.invalidColor;
      }

      final existingIndex = _workspace.boards.indexWhere(
        (board) => board.id == id,
      );
      if (existingIndex == -1) {
        return StickyBoardMutationResult.notFound;
      }
      final normalizedName = name.trim();
      if (_workspace.boards.any(
        (board) => board.id != id && _sameName(board.name, normalizedName),
      )) {
        return StickyBoardMutationResult.duplicateName;
      }

      final existingBoard = _workspace.boards[existingIndex];
      if (existingBoard.name == normalizedName &&
          existingBoard.colorValue == colorValue) {
        return StickyBoardMutationResult.success;
      }
      final updatedBoards = List<StickyBoard>.of(_workspace.boards);
      updatedBoards[existingIndex] = existingBoard.copyWith(
        name: normalizedName,
        colorValue: colorValue,
      );
      return await _save(
            StickyBoardWorkspace(
              boards: updatedBoards,
              boardTodoIds: _workspace.boardTodoIds,
            ),
          )
          ? StickyBoardMutationResult.success
          : StickyBoardMutationResult.storageFailure;
    });
  }

  Future<StickyBoardMutationResult> deleteBoard(String id) {
    return _enqueueMutation(() async {
      if (boardById(id) == null) {
        return StickyBoardMutationResult.notFound;
      }
      final updatedRelations = <String, Iterable<String>>{
        ..._workspace.boardTodoIds,
      }..remove(id);
      return await _save(
            StickyBoardWorkspace(
              boards: _workspace.boards.where((board) => board.id != id),
              boardTodoIds: updatedRelations,
            ),
          )
          ? StickyBoardMutationResult.success
          : StickyBoardMutationResult.storageFailure;
    });
  }

  Future<bool> setPinned(String boardId, bool isPinned) {
    return _enqueueMutation(() async {
      final existingIndex = _workspace.boards.indexWhere(
        (board) => board.id == boardId,
      );
      if (existingIndex == -1) {
        return false;
      }
      final existingBoard = _workspace.boards[existingIndex];
      if (existingBoard.isPinned == isPinned) {
        return true;
      }
      final updatedBoards = List<StickyBoard>.of(_workspace.boards);
      updatedBoards[existingIndex] = existingBoard.copyWith(isPinned: isPinned);
      return _save(
        StickyBoardWorkspace(
          boards: updatedBoards,
          boardTodoIds: _workspace.boardTodoIds,
        ),
      );
    });
  }

  Future<bool> saveWindowFrame({
    required String boardId,
    required StickyBoardWindowFrame frame,
  }) {
    return _enqueueMutation(() async {
      final existingIndex = _workspace.boards.indexWhere(
        (board) => board.id == boardId,
      );
      if (existingIndex == -1) {
        return false;
      }
      final existingBoard = _workspace.boards[existingIndex];
      if (existingBoard.windowFrame == frame) {
        return true;
      }
      final updatedBoards = List<StickyBoard>.of(_workspace.boards);
      updatedBoards[existingIndex] = existingBoard.copyWith(windowFrame: frame);
      return _save(
        StickyBoardWorkspace(
          boards: updatedBoards,
          boardTodoIds: _workspace.boardTodoIds,
        ),
      );
    });
  }

  Future<bool> addTodo({required String boardId, required String todoId}) {
    return _enqueueMutation(() async {
      if (boardById(boardId) == null || todoId.trim().isEmpty) {
        return false;
      }
      final currentTodoIds = todoIdsForBoard(boardId);
      if (currentTodoIds.contains(todoId)) {
        return true;
      }
      return _save(
        StickyBoardWorkspace(
          boards: _workspace.boards,
          boardTodoIds: <String, Iterable<String>>{
            ..._workspace.boardTodoIds,
            boardId: <String>[...currentTodoIds, todoId],
          },
        ),
      );
    });
  }

  Future<bool> removeTodo({required String boardId, required String todoId}) {
    return _enqueueMutation(() async {
      if (boardById(boardId) == null) {
        return false;
      }
      final currentTodoIds = todoIdsForBoard(boardId);
      if (!currentTodoIds.contains(todoId)) {
        return true;
      }
      final updatedRelations = <String, Iterable<String>>{
        ..._workspace.boardTodoIds,
      };
      final remainingTodoIds = currentTodoIds
          .where((id) => id != todoId)
          .toList(growable: false);
      if (remainingTodoIds.isEmpty) {
        updatedRelations.remove(boardId);
      } else {
        updatedRelations[boardId] = remainingTodoIds;
      }
      return _save(
        StickyBoardWorkspace(
          boards: _workspace.boards,
          boardTodoIds: updatedRelations,
        ),
      );
    });
  }

  Future<bool> setTodoMembership({
    required String boardId,
    required String todoId,
    required bool selected,
  }) {
    if (selected) {
      return addTodo(boardId: boardId, todoId: todoId);
    }
    return removeTodo(boardId: boardId, todoId: todoId);
  }

  void dismissError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  Future<T> _enqueueMutation<T>(Future<T> Function() mutation) {
    final operation = _mutationQueue.then((_) => mutation());
    _mutationQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<bool> _save(StickyBoardWorkspace workspace) async {
    try {
      await _storage.save(workspace);
      _workspace = workspace;
      _error = null;
      notifyListeners();
      return true;
    } on StorageFailure catch (error) {
      _error = error;
      notifyListeners();
      return false;
    }
  }

  static StickyBoardMutationResult _validateName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return StickyBoardMutationResult.emptyName;
    }
    if (normalizedName.characters.length > StickyBoard.maxNameLength) {
      return StickyBoardMutationResult.nameTooLong;
    }
    return StickyBoardMutationResult.success;
  }

  static bool _sameName(String left, String right) {
    return left.toLowerCase() == right.toLowerCase();
  }

  static bool _isValidColorValue(int value) {
    return !value.isNegative && value <= 0xFFFFFFFF;
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
