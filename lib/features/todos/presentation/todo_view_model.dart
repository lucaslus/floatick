import 'dart:io';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/storage_failure.dart';
import '../data/first_run_workspace_seeder.dart';
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

enum TodoProgressFilter { all, doing }

class TodoViewModel extends ChangeNotifier {
  TodoViewModel({
    required TodoRepository todoRepository,
    required TagRepository tagRepository,
    TodoClock? clock,
    TodoIdGenerator? idGenerator,
    TagIdGenerator? tagIdGenerator,
    FirstRunWorkspaceSeeder? firstRunWorkspaceSeeder,
  }) : _repository = todoRepository,
       // The public named parameter cannot use the private field's identifier.
       // ignore: prefer_initializing_formals
       _tagRepository = tagRepository,
       _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateUuidV4,
       _tagIdGenerator = tagIdGenerator ?? _generateUuidV4,
       // The public named parameter cannot use the private field's identifier.
       // ignore: prefer_initializing_formals
       _firstRunWorkspaceSeeder = firstRunWorkspaceSeeder;

  final TodoRepository _repository;
  final TagRepository _tagRepository;
  final TodoClock _clock;
  final TodoIdGenerator _idGenerator;
  final TagIdGenerator _tagIdGenerator;
  final FirstRunWorkspaceSeeder? _firstRunWorkspaceSeeder;

  static const String untitledFallback = 'Untitled todo';

  List<TodoItem> _items = const <TodoItem>[];
  Map<String, TodoItem> _itemsById = const <String, TodoItem>{};
  List<TodoItem> _activeViewItems = const <TodoItem>[];
  List<TodoItem> _archivedViewItems = const <TodoItem>[];
  Map<String, String> _normalizedTitlesByTodoId = const <String, String>{};
  Map<String, List<String>> _normalizedTagNamesByTodoId =
      const <String, List<String>>{};
  int _activeCount = 0;
  int _archivedCount = 0;
  bool? _cachedViewArchived;
  String? _cachedViewQuery;
  Set<String> _cachedViewTagIds = const <String>{};
  TodoProgressFilter? _cachedViewProgressFilter;
  List<TodoItem>? _cachedViewItems;
  TagWorkspace _tagWorkspace = TagWorkspace.empty();
  Map<String, int> _tagUsageCounts = const <String, int>{};
  StorageFailure? _error;
  bool _isLoading = false;
  Future<void> _mutationQueue = Future<void>.value();
  Future<void> _tagMutationQueue = Future<void>.value();

  List<TodoItem> get items => _items;
  List<TodoTag> get tags => _tagWorkspace.tags;
  StorageFailure? get error => _error;
  bool get isLoading => _isLoading;
  String get storageDirectoryPath => File(_repository.storagePath).parent.path;

  int get activeCount => _activeCount;

  int get archivedCount => _archivedCount;

  TodoItem? itemById(String id) => _itemsById[id];

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

  int tagUsageCount(String tagId) => _tagUsageCounts[tagId] ?? 0;

  Map<String, int> tagUsageCountsFor(Iterable<String> tagIds) {
    return Map<String, int>.unmodifiable(<String, int>{
      for (final tagId in tagIds) tagId: _tagUsageCounts[tagId] ?? 0,
    });
  }

  List<TodoItem> itemsForView({
    required bool archived,
    required String query,
    Set<String> selectedTagIds = const <String>{},
    TodoProgressFilter progressFilter = TodoProgressFilter.all,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (_cachedViewItems != null &&
        _cachedViewArchived == archived &&
        _cachedViewQuery == normalizedQuery &&
        setEquals(_cachedViewTagIds, selectedTagIds) &&
        _cachedViewProgressFilter == progressFilter) {
      return _cachedViewItems!;
    }

    final sourceItems = archived ? _archivedViewItems : _activeViewItems;
    final visibleItems = sourceItems.where((item) {
      final assignedTagIds = tagIdsForTodo(item.id);
      final matchesTag =
          selectedTagIds.isEmpty || selectedTagIds.any(assignedTagIds.contains);
      final matchesQuery =
          normalizedQuery.isEmpty ||
          (_normalizedTitlesByTodoId[item.id] ?? '').contains(
            normalizedQuery,
          ) ||
          (_normalizedTagNamesByTodoId[item.id] ?? const <String>[]).any(
            (name) => name.contains(normalizedQuery),
          );
      final matchesProgress = switch (progressFilter) {
        TodoProgressFilter.all => true,
        TodoProgressFilter.doing => item.isDoing,
      };
      return matchesTag && matchesQuery && matchesProgress;
    }).toList();
    _cachedViewArchived = archived;
    _cachedViewQuery = normalizedQuery;
    _cachedViewTagIds = Set<String>.unmodifiable(selectedTagIds);
    _cachedViewProgressFilter = progressFilter;
    _cachedViewItems = List<TodoItem>.unmodifiable(visibleItems);
    return _cachedViewItems!;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    StorageFailure? loadError;
    try {
      await _firstRunWorkspaceSeeder?.seedIfNeeded();
    } on StorageFailure catch (error) {
      loadError = error;
    }

    try {
      _setItems(await _repository.load());
    } on StorageFailure catch (error) {
      loadError = error;
    }

    try {
      _setTagWorkspace(await _tagRepository.load());
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
  }) async {
    return await create(title, content: content, tagIds: tagIds) != null;
  }

  Future<TodoItem?> create(
    String title, {
    String content = '',
    Iterable<String> tagIds = const <String>[],
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty && content.trim().isEmpty) {
      return Future<TodoItem?>.value(null);
    }
    final resolvedTitle = normalizedTitle.isEmpty
        ? untitledFallback
        : normalizedTitle;

    final todoId = _idGenerator();
    return _enqueueTodoAndTagMutation(() async {
      if (_items.any((item) => item.id == todoId)) {
        return null;
      }
      final normalizedTagIds = _normalizeKnownTagIds(tagIds);
      if (normalizedTagIds == null) {
        return null;
      }
      final createdItem = TodoItem(
        id: todoId,
        title: resolvedTitle,
        content: content,
        createdAt: _clock().toUtc(),
      );
      final updatedItems = <TodoItem>[..._items, createdItem];
      final updatedWorkspace = _workspaceWithTodoTags(
        todoId: todoId,
        tagIds: normalizedTagIds,
      );
      final saved = await _commitTodoAndTags(
        updatedItems: updatedItems,
        updatedWorkspace: updatedWorkspace,
        todoChanged: true,
        tagsChanged: normalizedTagIds.isNotEmpty,
      );
      return saved ? createdItem : null;
    });
  }

  Future<void> toggleCompletion(String id) {
    return _updateItem(id, (item) {
      if (item.isArchived) {
        return item;
      }
      return item.withCompletedAt(item.isCompleted ? null : _clock().toUtc());
    });
  }

  Future<void> toggleDoing(String id) {
    return _updateItem(id, (item) {
      if (item.isArchived || item.isCompleted) {
        return item;
      }
      return item.withStartedAt(item.isDoing ? null : _clock().toUtc());
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
    if (existingItem.isArchived) {
      return false;
    }
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
    if (normalizedTitle.isEmpty && content.trim().isEmpty) {
      return Future<bool>.value(false);
    }
    final resolvedTitle = normalizedTitle.isEmpty
        ? untitledFallback
        : normalizedTitle;

    return _enqueueTodoAndTagMutation(() async {
      final existingIndex = _items.indexWhere((item) => item.id == id);
      if (existingIndex == -1) {
        return false;
      }
      final existingItem = _items[existingIndex];
      if (existingItem.isArchived) {
        return false;
      }
      final normalizedTagIds = tagIds == null
          ? tagIdsForTodo(id)
          : _normalizeKnownTagIds(tagIds);
      if (normalizedTagIds == null) {
        return false;
      }

      final todoChanged =
          existingItem.title != resolvedTitle ||
          existingItem.content != content;
      final tagsChanged = !listEquals(tagIdsForTodo(id), normalizedTagIds);
      if (!todoChanged && !tagsChanged) {
        return true;
      }

      final updatedItems = List<TodoItem>.of(_items);
      if (todoChanged) {
        updatedItems[existingIndex] = existingItem.withDetails(
          title: resolvedTitle,
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

  Future<bool> deletePermanently(String id) {
    return _enqueueTodoAndTagMutation(() async {
      final existingItem = itemById(id);
      if (existingItem == null || !existingItem.isArchived) {
        return false;
      }

      final updatedAssignments = <String, Iterable<String>>{
        ..._tagWorkspace.assignments,
      }..remove(id);
      return _commitTodoAndTags(
        updatedItems: _items.where((item) => item.id != id).toList(),
        updatedWorkspace: TagWorkspace(
          tags: _tagWorkspace.tags,
          assignments: updatedAssignments,
        ),
        todoChanged: true,
        tagsChanged: _tagWorkspace.assignments.containsKey(id),
      );
    });
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

  Future<bool> toggleTagForTodo({
    required String todoId,
    required String tagId,
  }) {
    return _enqueueTagMutation(() async {
      final todo = itemById(todoId);
      if (todo == null || todo.isArchived || tagById(tagId) == null) {
        return false;
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

      return _saveTagWorkspace(
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
      _setItems(updatedItems);
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
      _setItems(updatedItems);
      _setTagWorkspace(updatedWorkspace);
      _error = null;
      notifyListeners();
      return true;
    } on StorageFailure catch (error) {
      if (todoSaved && tagsChanged) {
        try {
          await _repository.save(_items);
        } on StorageFailure {
          try {
            await _tagRepository.save(updatedWorkspace);
            _setItems(updatedItems);
            _setTagWorkspace(updatedWorkspace);
            _error = null;
            notifyListeners();
            return true;
          } on StorageFailure catch (recoveryError) {
            _setItems(updatedItems);
            _error = recoveryError;
            notifyListeners();
            return false;
          }
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
      _setTagWorkspace(workspace);
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

  void _setTagWorkspace(TagWorkspace workspace) {
    final usageCounts = <String, int>{
      for (final tag in workspace.tags) tag.id: 0,
    };
    for (final assignedTagIds in workspace.assignments.values) {
      for (final tagId in assignedTagIds) {
        final currentCount = usageCounts[tagId];
        if (currentCount != null) {
          usageCounts[tagId] = currentCount + 1;
        }
      }
    }
    _tagWorkspace = workspace;
    _tagUsageCounts = Map<String, int>.unmodifiable(usageCounts);
    final normalizedTagNamesById = <String, String>{
      for (final tag in workspace.tags) tag.id: tag.name.toLowerCase(),
    };
    _normalizedTagNamesByTodoId =
        Map<String, List<String>>.unmodifiable(<String, List<String>>{
          for (final assignment in workspace.assignments.entries)
            assignment.key: List<String>.unmodifiable(
              assignment.value
                  .map((tagId) => normalizedTagNamesById[tagId])
                  .whereType<String>(),
            ),
        });
    _invalidateViewCache();
  }

  void _setItems(Iterable<TodoItem> items) {
    final immutableItems = List<TodoItem>.unmodifiable(items);
    final itemsById = <String, TodoItem>{};
    for (final item in immutableItems) {
      itemsById.putIfAbsent(item.id, () => item);
    }

    final activeViewItems =
        immutableItems.where((item) => !item.isArchived).toList(growable: false)
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final archivedViewItems =
        immutableItems.where((item) => item.isArchived).toList(growable: false)
          ..sort((left, right) {
            final leftDate = left.archivedAt ?? left.createdAt;
            final rightDate = right.archivedAt ?? right.createdAt;
            return rightDate.compareTo(leftDate);
          });

    _items = immutableItems;
    _itemsById = Map<String, TodoItem>.unmodifiable(itemsById);
    _activeViewItems = List<TodoItem>.unmodifiable(activeViewItems);
    _archivedViewItems = List<TodoItem>.unmodifiable(archivedViewItems);
    _normalizedTitlesByTodoId = Map<String, String>.unmodifiable(
      <String, String>{
        for (final item in immutableItems) item.id: item.title.toLowerCase(),
      },
    );
    _activeCount = activeViewItems.where((item) => !item.isCompleted).length;
    _archivedCount = archivedViewItems.length;
    _invalidateViewCache();
  }

  void _invalidateViewCache() {
    _cachedViewArchived = null;
    _cachedViewQuery = null;
    _cachedViewTagIds = const <String>{};
    _cachedViewProgressFilter = null;
    _cachedViewItems = null;
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
