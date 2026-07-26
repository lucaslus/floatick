import 'sticky_board.dart';

class StickyBoardWorkspace {
  StickyBoardWorkspace({
    required Iterable<StickyBoard> boards,
    required Map<String, Iterable<String>> boardTodoIds,
  }) : boards = List<StickyBoard>.unmodifiable(boards),
       boardTodoIds = Map<String, List<String>>.unmodifiable(
         boardTodoIds.map(
           (boardId, todoIds) =>
               MapEntry(boardId, List<String>.unmodifiable(todoIds.toSet())),
         ),
       );

  factory StickyBoardWorkspace.empty() {
    return StickyBoardWorkspace(
      boards: const <StickyBoard>[],
      boardTodoIds: const <String, List<String>>{},
    );
  }

  final List<StickyBoard> boards;
  final Map<String, List<String>> boardTodoIds;

  List<String> todoIdsForBoard(String boardId) {
    return boardTodoIds[boardId] ?? const <String>[];
  }

  factory StickyBoardWorkspace.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException(
        'Sticky board workspace field "version" must equal 1.',
      );
    }

    final rawBoards = json['boards'];
    if (rawBoards is! List<dynamic>) {
      throw const FormatException(
        'Sticky board workspace field "boards" must be a JSON array.',
      );
    }
    final boards = rawBoards
        .map((entry) {
          if (entry is! Map<dynamic, dynamic>) {
            throw const FormatException(
              'Each sticky board must be a JSON object.',
            );
          }
          return StickyBoard.fromJson(Map<String, dynamic>.from(entry));
        })
        .toList(growable: false);
    if (boards.map((board) => board.id).toSet().length != boards.length) {
      throw const FormatException('Sticky board ids must be unique.');
    }
    if (boards.map((board) => board.name.toLowerCase()).toSet().length !=
        boards.length) {
      throw const FormatException(
        'Sticky board names must be unique regardless of letter case.',
      );
    }
    final knownBoardIds = boards.map((board) => board.id).toSet();

    final rawBoardTodoIds = json['boardTodoIds'];
    if (rawBoardTodoIds is! Map<dynamic, dynamic>) {
      throw const FormatException(
        'Sticky board workspace field "boardTodoIds" must be a JSON object.',
      );
    }
    final boardTodoIds = <String, List<String>>{};
    for (final entry in rawBoardTodoIds.entries) {
      if (entry.key is! String ||
          !knownBoardIds.contains(entry.key) ||
          entry.value is! List<dynamic>) {
        throw const FormatException(
          'Each sticky board relation must reference an existing board.',
        );
      }
      final todoIds = <String>[];
      for (final todoId in entry.value as List<dynamic>) {
        if (todoId is! String || todoId.trim().isEmpty) {
          throw const FormatException(
            'Sticky board todo ids must be non-empty strings.',
          );
        }
        todoIds.add(todoId);
      }
      boardTodoIds[entry.key as String] = todoIds;
    }

    return StickyBoardWorkspace(boards: boards, boardTodoIds: boardTodoIds);
  }

  Map<String, dynamic> toJson() {
    final sortedRelations = boardTodoIds.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return <String, dynamic>{
      'version': 1,
      'boards': boards.map((board) => board.toJson()).toList(growable: false),
      'boardTodoIds': <String, dynamic>{
        for (final entry in sortedRelations) entry.key: entry.value,
      },
    };
  }
}
