import 'dart:io';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/storage_failure.dart';
import '../data/tag_repository.dart';
import '../data/todo_repository.dart';
import '../domain/tag_workspace.dart';
import '../domain/todo_item.dart';
import '../domain/todo_tag.dart';

typedef TodoClock = DateTime Function();
typedef TodoIdGenerator = String Function();
typedef TagIdGenerator = String Function();

enum TagMutationResult {
  success,
  emptyName,
  nameTooLong,
  duplicateName,
  notFound,
  invalidColor,
  storageFailure,
}

class TodoViewModel extends ChangeNotifier {
  TodoViewModel({
    required TodoRepository todoRepository,
    required TagRepository tagRepository,
    TodoClock? clock,
    TodoIdGenerator? idGenerator,
    TagIdGenerator? tagIdGenerator,
  }) : _repository = todoRepository,
       // The public named parameter cannot use the private field's identifier.
       // ignore: prefer_initializing_formals
       _tagRepository = tagRepository,
       _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateUuidV4,
       _tagIdGenerator = tagIdGenerator ?? _generateUuidV4;

  final TodoRepository _repository;
  final TagRepository _tagRepository;
  final TodoClock _clock;
  final TodoIdGenerator _idGenerator;
  final TagIdGenerator _tagIdGenerator;

  List<TodoItem> _items = <TodoItem>[];
  TagWorkspace _tagWorkspace = TagWorkspace.empty();
  StorageFailure? _error;
  bool _isLoading = false;
  Future<void> _mutationQueue = Future<void>.value();
  Future<void> _tagMutationQueue = Future<void>.value();

  List<TodoItem> get items => List<TodoItem>.unmodifiable(_items);
  List<TodoTag> get tags => _tagWorkspace.tags;
  StorageFailure? get error => _error;
  bool get isLoading => _isLoading;
  String get storageDirectoryPath => File(_repository.storagePath).parent.path;

  int get activeCount {
    return _items.where((item) => !item.isArchived && !item.isCompleted).length;
  }

  int get archivedCount => _items.where((item) => item.isArchived).length;

  TodoItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  TodoTag? tagById(String id) {
    for (final tag in _tagWorkspace.tags) {
      if (tag.id == id) {
        return tag;
      }
    }
    return null;
  }

  List<String> tagIdsForTodo(String todoId) {
    return _tagWorkspace.tagIdsForTodo(todoId);
  }

  List<TodoTag> tagsForTodo(String todoId) {
    final assignedTagIds = tagIdsForTodo(todoId).toSet();
    return List<TodoTag>.unmodifiable(
      _tagWorkspace.tags.where((tag) => assignedTagIds.contains(tag.id)),
    );
  }

  int tagUsageCount(String tagId) {
    return _tagWorkspace.assignments.values
        .where((tagIds) => tagIds.contains(tagId))
        .length;
  }

  List<TodoItem> itemsForView({
    required bool archived,
    required String query,
    String? selectedTagId,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final visibleItems = _items.where((item) {
      final matchesScope = archived ? item.isArchived : !item.isArchived;
      final assignedTagIds = tagIdsForTodo(item.id);
      final matchesTag =
          selectedTagId == null || assignedTagIds.contains(selectedTagId);
      final assignedTagNames = _tagWorkspace.tags
          .where((tag) => assignedTagIds.contains(tag.id))
          .map((tag) => tag.name.toLowerCase());
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.content.toLowerCase().contains(normalizedQuery) ||
          assignedTagNames.any((name) => name.contains(normalizedQuery));
      return matchesScope && matchesTag && matchesQuery;
    }).toList();

    DateTime relevantDate(TodoItem item) {
      if (archived) {
        return item.archivedAt ?? item.createdAt;
      }
      return item.createdAt;
    }

    visibleItems.sort((left, right) {
      return relevantDate(right).compareTo(relevantDate(left));
    });
    return List<TodoItem>.unmodifiable(visibleItems);
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    StorageFailure? loadError;
    try {
      _items = await _repository.load();
    } on StorageFailure catch (error) {
      loadError = error;
    }

    try {
      _tagWorkspace = await _tagRepository.load();
    } on StorageFailure catch (error) {
      loadError ??= error;
    } finally {
      _error = loadError;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add(
    String title, {
    String content = '',
    Iterable<String> tagIds = const <String>[],
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      return Future<bool>.value(false);
    }

    final todoId = _idGenerator();
    return _enqueueTodoAndTagMutation(() async {
      if (_items.any((item) => item.id == todoId)) {
        return false;
      }
      final normalizedTagIds = _normalizeKnownTagIds(tagIds);
      if (normalizedTagIds == null) {
        return false;
      }
      final updatedItems = <TodoItem>[
        ..._items,
        TodoItem(
          id: todoId,
          title: normalizedTitle,
          content: content,
          createdAt: _clock().toUtc(),
        ),
      ];
      final updatedWorkspace = _workspaceWithTodoTags(
        todoId: todoId,
        tagIds: normalizedTagIds,
      );
      return _commitTodoAndTags(
        updatedItems: updatedItems,
        updatedWorkspace: updatedWorkspace,
        todoChanged: true,
        tagsChanged: normalizedTagIds.isNotEmpty,
      );
    });
  }

  Future<void> toggleCompletion(String id) {
    return _updateItem(id, (item) {
      return item.withCompletedAt(item.isCompleted ? null : _clock().toUtc());
    });
  }

  Future<bool> rename(String id, String title) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      return false;
    }

    final existingIndex = _items.indexWhere((item) => item.id == id);
    if (existingIndex == -1) {
      return false;
    }
    final existingItem = _items[existingIndex];
    if (existingItem.title == normalizedTitle) {
      return true;
    }

    await _updateItem(id, (item) => item.withTitle(normalizedTitle));
    return _items.any((item) => item.id == id && item.title == normalizedTitle);
  }

  Future<bool> updateDetails({
    required String id,
    required String title,
    required String content,
    Iterable<String>? tagIds,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      return Future<bool>.value(false);
    }

    return _enqueueTodoAndTagMutation(() async {
      final existingIndex = _items.indexWhere((item) => item.id == id);
      if (existingIndex == -1) {
        return false;
      }
      final normalizedTagIds = tagIds == null
          ? tagIdsForTodo(id)
          : _normalizeKnownTagIds(tagIds);
      if (normalizedTagIds == null) {
        return false;
      }

      final existingItem = _items[existingIndex];
      final todoChanged =
          existingItem.title != normalizedTitle ||
          existingItem.content != content;
      final tagsChanged = !listEquals(tagIdsForTodo(id), normalizedTagIds);
      if (!todoChanged && !tagsChanged) {
        return true;
      }

      final updatedItems = List<TodoItem>.of(_items);
      if (todoChanged) {
        updatedItems[existingIndex] = existingItem.withDetails(
          title: normalizedTitle,
          content: content,
        );
      }
      return _commitTodoAndTags(
        updatedItems: updatedItems,
        updatedWorkspace: _workspaceWithTodoTags(
          todoId: id,
          tagIds: normalizedTagIds,
        ),
        todoChanged: todoChanged,
        tagsChanged: tagsChanged,
      );
    });
  }

  Future<void> archive(String id) {
    return _updateItem(id, (item) => item.withArchivedAt(_clock().toUtc()));
  }

  Future<void> restore(String id) {
    return _updateItem(id, (item) => item.withArchivedAt(null));
  }

  Future<TagMutationResult> createTag({
    required String name,
    required int colorValue,
  }) {
    return _enqueueTagMutation(() async {
      final validation = _validateTagName(name);
      if (validation != TagMutationResult.success) {
        return validation;
      }
      if (!_isValidColorValue(colorValue)) {
        return TagMutationResult.invalidColor;
      }

      final normalizedName = name.trim();
      if (_tagWorkspace.tags.any(
        (tag) => _sameTagName(tag.name, normalizedName),
      )) {
        return TagMutationResult.duplicateName;
      }

      final updatedWorkspace = TagWorkspace(
        tags: <TodoTag>[
          ..._tagWorkspace.tags,
          TodoTag(
            id: _tagIdGenerator(),
            name: normalizedName,
            colorValue: colorValue,
            createdAt: _clock().toUtc(),
          ),
        ],
        assignments: _tagWorkspace.assignments,
      );
      return await _saveTagWorkspace(updatedWorkspace)
          ? TagMutationResult.success
          : TagMutationResult.storageFailure;
    });
  }

  Future<TagMutationResult> updateTag({
    required String id,
    required String name,
    required int colorValue,
  }) {
    return _enqueueTagMutation(() async {
      final validation = _validateTagName(name);
      if (validation != TagMutationResult.success) {
        return validation;
      }
      if (!_isValidColorValue(colorValue)) {
        return TagMutationResult.invalidColor;
      }

      final existingIndex = _tagWorkspace.tags.indexWhere(
        (tag) => tag.id == id,
      );
      if (existingIndex == -1) {
        return TagMutationResult.notFound;
      }

      final normalizedName = name.trim();
      if (_tagWorkspace.tags.any(
        (tag) => tag.id != id && _sameTagName(tag.name, normalizedName),
      )) {
        return TagMutationResult.duplicateName;
      }

      final existingTag = _tagWorkspace.tags[existingIndex];
      if (existingTag.name == normalizedName &&
          existingTag.colorValue == colorValue) {
        return TagMutationResult.success;
      }

      final updatedTags = List<TodoTag>.of(_tagWorkspace.tags);
      updatedTags[existingIndex] = existingTag.copyWith(
        name: normalizedName,
        colorValue: colorValue,
      );
      final updatedWorkspace = TagWorkspace(
        tags: updatedTags,
        assignments: _tagWorkspace.assignments,
      );
      return await _saveTagWorkspace(updatedWorkspace)
          ? TagMutationResult.success
          : TagMutationResult.storageFailure;
    });
  }

  Future<TagMutationResult> deleteTag(String id) {
    return _enqueueTagMutation(() async {
      if (tagById(id) == null) {
        return TagMutationResult.notFound;
      }

      final updatedAssignments = <String, Iterable<String>>{};
      for (final entry in _tagWorkspace.assignments.entries) {
        final remainingTagIds = entry.value
            .where((tagId) => tagId != id)
            .toList(growable: false);
        if (remainingTagIds.isNotEmpty) {
          updatedAssignments[entry.key] = remainingTagIds;
        }
      }
      final updatedWorkspace = TagWorkspace(
        tags: _tagWorkspace.tags.where((tag) => tag.id != id),
        assignments: updatedAssignments,
      );
      return await _saveTagWorkspace(updatedWorkspace)
          ? TagMutationResult.success
          : TagMutationResult.storageFailure;
    });
  }

  Future<void> toggleTagForTodo({
    required String todoId,
    required String tagId,
  }) {
    return _enqueueTagMutation(() async {
      final todoExists = _items.any((item) => item.id == todoId);
      if (!todoExists || tagById(tagId) == null) {
        return;
      }

      final assignedTagIds = tagIdsForTodo(todoId).toSet();
      if (!assignedTagIds.add(tagId)) {
        assignedTagIds.remove(tagId);
      }
      final updatedAssignments = <String, Iterable<String>>{
        ..._tagWorkspace.assignments,
      };
      if (assignedTagIds.isEmpty) {
        updatedAssignments.remove(todoId);
      } else {
        updatedAssignments[todoId] = _tagWorkspace.tags
            .where((tag) => assignedTagIds.contains(tag.id))
            .map((tag) => tag.id);
      }

      await _saveTagWorkspace(
        TagWorkspace(tags: _tagWorkspace.tags, assignments: updatedAssignments),
      );
    });
  }

  void dismissError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  Future<void> _updateItem(String id, TodoItem Function(TodoItem item) update) {
    return _enqueueMutation((currentItems) {
      final index = currentItems.indexWhere((item) => item.id == id);
      if (index == -1) {
        return currentItems;
      }

      final updatedItems = List<TodoItem>.of(currentItems);
      updatedItems[index] = update(updatedItems[index]);
      return updatedItems;
    });
  }

  Future<void> _enqueueMutation(
    List<TodoItem> Function(List<TodoItem> currentItems) update,
  ) {
    final operation = _mutationQueue.then((_) => _commit(update));
    _mutationQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _commit(
    List<TodoItem> Function(List<TodoItem> currentItems) update,
  ) async {
    final currentItems = List<TodoItem>.of(_items);
    final updatedItems = update(currentItems);
    if (listEquals(updatedItems, _items)) {
      return;
    }

    try {
      await _repository.save(updatedItems);
      _items = updatedItems;
      _error = null;
    } on StorageFailure catch (error) {
      _error = error;
    }
    notifyListeners();
  }

  Future<T> _enqueueTagMutation<T>(Future<T> Function() mutation) {
    final operation = _tagMutationQueue.then((_) => mutation());
    _tagMutationQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<T> _enqueueTodoAndTagMutation<T>(Future<T> Function() mutation) {
    final operation = Future.wait<void>(<Future<void>>[
      _mutationQueue,
      _tagMutationQueue,
    ]).then((_) => mutation());
    final barrier = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _mutationQueue = barrier;
    _tagMutationQueue = barrier;
    return operation;
  }

  List<String>? _normalizeKnownTagIds(Iterable<String> tagIds) {
    final requestedTagIds = tagIds.toSet();
    final knownTagIds = _tagWorkspace.tags.map((tag) => tag.id).toSet();
    if (!knownTagIds.containsAll(requestedTagIds)) {
      return null;
    }
    return _tagWorkspace.tags
        .where((tag) => requestedTagIds.contains(tag.id))
        .map((tag) => tag.id)
        .toList(growable: false);
  }

  TagWorkspace _workspaceWithTodoTags({
    required String todoId,
    required List<String> tagIds,
  }) {
    final assignments = <String, Iterable<String>>{
      ..._tagWorkspace.assignments,
    };
    if (tagIds.isEmpty) {
      assignments.remove(todoId);
    } else {
      assignments[todoId] = tagIds;
    }
    return TagWorkspace(tags: _tagWorkspace.tags, assignments: assignments);
  }

  Future<bool> _commitTodoAndTags({
    required List<TodoItem> updatedItems,
    required TagWorkspace updatedWorkspace,
    required bool todoChanged,
    required bool tagsChanged,
  }) async {
    var todoSaved = false;
    try {
      if (todoChanged) {
        await _repository.save(updatedItems);
        todoSaved = true;
      }
      if (tagsChanged) {
        await _tagRepository.save(updatedWorkspace);
      }
      _items = updatedItems;
      _tagWorkspace = updatedWorkspace;
      _error = null;
      notifyListeners();
      return true;
    } on StorageFailure catch (error) {
      if (todoSaved && tagsChanged) {
        try {
          await _repository.save(_items);
        } on StorageFailure catch (rollbackError) {
          _items = updatedItems;
          _error = rollbackError;
          notifyListeners();
          return true;
        }
      }
      _error = error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _saveTagWorkspace(TagWorkspace workspace) async {
    try {
      await _tagRepository.save(workspace);
      _tagWorkspace = workspace;
      _error = null;
      notifyListeners();
      return true;
    } on StorageFailure catch (error) {
      _error = error;
      notifyListeners();
      return false;
    }
  }

  static TagMutationResult _validateTagName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return TagMutationResult.emptyName;
    }
    if (normalizedName.characters.length > TodoTag.maxNameLength) {
      return TagMutationResult.nameTooLong;
    }
    return TagMutationResult.success;
  }

  static bool _sameTagName(String left, String right) {
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
