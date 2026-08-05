import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/storage/storage_failure.dart';
import '../data/note_repository.dart';
import '../domain/note_item.dart';

typedef NoteClock = DateTime Function();
typedef NoteIdGenerator = String Function();

class NoteViewModel extends ChangeNotifier {
  NoteViewModel({
    required this._repository,
    NoteClock? clock,
    NoteIdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateUuidV4;

  static const String untitledFallback = 'Untitled note';

  final NoteRepository _repository;
  final NoteClock _clock;
  final NoteIdGenerator _idGenerator;

  List<NoteItem> _items = const <NoteItem>[];
  Map<String, NoteItem> _itemsById = const <String, NoteItem>{};
  StorageFailure? _error;
  bool _isLoading = false;
  Future<void> _mutationQueue = Future<void>.value();

  List<NoteItem> get items => _items;
  StorageFailure? get error => _error;
  bool get isLoading => _isLoading;
  int get activeCount => _items.where((item) => !item.isArchived).length;
  int get archivedCount => _items.where((item) => item.isArchived).length;

  NoteItem? itemById(String id) => _itemsById[id];

  List<NoteItem> itemsForView({
    required bool archived,
    required String query,
    Iterable<String> selectedTagIds = const <String>[],
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final selectedTags = selectedTagIds.toSet();
    final visibleItems = _items
        .where((item) {
          if (item.isArchived != archived) {
            return false;
          }
          if (selectedTags.isNotEmpty &&
              !selectedTags.any(item.tagIds.contains)) {
            return false;
          }
          return normalizedQuery.isEmpty ||
              item.title.toLowerCase().contains(normalizedQuery) ||
              item.content.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    visibleItems.sort((left, right) {
      if (!archived && left.isPinned != right.isPinned) {
        return left.isPinned ? -1 : 1;
      }
      if (archived) {
        final leftDate = left.archivedAt ?? left.updatedAt;
        final rightDate = right.archivedAt ?? right.updatedAt;
        return rightDate.compareTo(leftDate);
      }
      return right.updatedAt.compareTo(left.updatedAt);
    });
    return List<NoteItem>.unmodifiable(visibleItems);
  }

  Map<String, int> tagUsageCountsFor(Iterable<String> tagIds) {
    final requestedTagIds = tagIds.toSet();
    final counts = <String, int>{for (final tagId in requestedTagIds) tagId: 0};
    for (final item in _items) {
      for (final tagId in item.tagIds) {
        if (requestedTagIds.contains(tagId)) {
          counts[tagId] = counts[tagId]! + 1;
        }
      }
    }
    return Map<String, int>.unmodifiable(counts);
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _setItems(await _repository.load());
    } on StorageFailure catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NoteItem?> save({
    String? id,
    required String title,
    required String content,
    Iterable<String>? tagIds,
  }) {
    final normalizedTitle = title.trim();
    if (id == null && normalizedTitle.isEmpty && content.trim().isEmpty) {
      return Future<NoteItem?>.value(null);
    }

    return _enqueueMutation<NoteItem?>(() async {
      final now = _clock().toUtc();
      if (id == null) {
        final resolvedTitle = normalizedTitle.isEmpty
            ? untitledFallback
            : normalizedTitle;
        final generatedId = _idGenerator();
        if (_itemsById.containsKey(generatedId)) {
          return null;
        }
        final item = NoteItem(
          id: generatedId,
          title: resolvedTitle,
          content: content,
          createdAt: now,
          updatedAt: now,
          tagIds: _normalizeTagIds(tagIds ?? const <String>[]),
        );
        return await _commit(<NoteItem>[..._items, item]) ? item : null;
      }

      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1 || _items[index].isArchived) {
        return null;
      }
      final existing = _items[index];
      final resolvedTagIds = tagIds == null
          ? existing.tagIds
          : _normalizeTagIds(tagIds);
      final resolvedTitle = normalizedTitle.isEmpty
          ? untitledFallback
          : normalizedTitle;
      if (existing.title == resolvedTitle &&
          existing.content == content &&
          listEquals(existing.tagIds, resolvedTagIds)) {
        return existing;
      }
      final updated = existing.withDetails(
        title: resolvedTitle,
        content: content,
        updatedAt: now,
        tagIds: resolvedTagIds,
      );
      final items = List<NoteItem>.of(_items)..[index] = updated;
      return await _commit(items) ? updated : null;
    });
  }

  static List<String> _normalizeTagIds(Iterable<String> tagIds) {
    return List<String>.unmodifiable(
      tagIds
          .map((tagId) => tagId.trim())
          .where((tagId) => tagId.isNotEmpty)
          .toSet(),
    );
  }

  Future<bool> togglePin(String id) {
    return _update(id, (item) {
      if (item.isArchived) {
        return item;
      }
      return item.withPinnedAt(item.isPinned ? null : _clock().toUtc());
    });
  }

  Future<bool> archive(String id) {
    final now = _clock().toUtc();
    return _update(
      id,
      (item) =>
          item.isArchived ? item : item.withArchivedAt(now, updatedAt: now),
    );
  }

  Future<bool> restore(String id) {
    final now = _clock().toUtc();
    return _update(
      id,
      (item) =>
          !item.isArchived ? item : item.withArchivedAt(null, updatedAt: now),
    );
  }

  Future<bool> deletePermanently(String id) {
    return _enqueueMutation<bool>(() async {
      final item = _itemsById[id];
      if (item == null || !item.isArchived) {
        return false;
      }
      return _commit(_items.where((candidate) => candidate.id != id).toList());
    });
  }

  Future<bool> removeTag(String tagId) {
    return _enqueueMutation<bool>(() async {
      var changed = false;
      final updatedItems = _items
          .map((item) {
            if (!item.tagIds.contains(tagId)) {
              return item;
            }
            changed = true;
            return item.withDetails(
              title: item.title,
              content: item.content,
              updatedAt: item.updatedAt,
              tagIds: item.tagIds.where((candidate) => candidate != tagId),
            );
          })
          .toList(growable: false);
      return !changed || await _commit(updatedItems);
    });
  }

  void dismissError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  Future<bool> _update(String id, NoteItem Function(NoteItem item) update) {
    return _enqueueMutation<bool>(() async {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) {
        return false;
      }
      final updated = update(_items[index]);
      if (updated == _items[index]) {
        return true;
      }
      final items = List<NoteItem>.of(_items)..[index] = updated;
      return _commit(items);
    });
  }

  Future<T> _enqueueMutation<T>(Future<T> Function() mutation) {
    final operation = _mutationQueue.then((_) => mutation());
    _mutationQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<bool> _commit(List<NoteItem> updatedItems) async {
    try {
      await _repository.save(updatedItems);
      _setItems(updatedItems);
      _error = null;
      notifyListeners();
      return true;
    } on StorageFailure catch (error) {
      _error = error;
      notifyListeners();
      return false;
    }
  }

  void _setItems(Iterable<NoteItem> items) {
    _items = List<NoteItem>.unmodifiable(items);
    _itemsById = Map<String, NoteItem>.unmodifiable(<String, NoteItem>{
      for (final item in _items) item.id: item,
    });
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
