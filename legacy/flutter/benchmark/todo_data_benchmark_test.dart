import 'dart:io';

import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A comparative data-path benchmark, not a UI frame-rate benchmark.
///
/// Run it explicitly:
/// `flutter test benchmark/todo_data_benchmark_test.dart --reporter expanded`
///
/// Results vary by hardware and build mode. Keep this outside `test/` so normal
/// unit-test runs do not treat wall-clock measurements as correctness gates.
void main() {
  test('todo data path benchmark', () async {
    const itemCounts = <int>[100, 1000, 5000, 10000];
    const tagCount = 8;
    final createdAt = DateTime.utc(2026, 7, 29, 8);

    debugPrint(
      'items,todo_save_ms,tag_save_ms,load_index_ms,'
      'cold_search_ms,cached_search_ms,tag_filter_ms,todo_bytes,tag_bytes',
    );

    for (final itemCount in itemCounts) {
      final directory = await Directory.systemTemp.createTemp(
        'floatick-data-benchmark-',
      );
      try {
        final todoRepository = LocalTodoRepository(rootDirectory: directory);
        final tagRepository = LocalTagRepository(rootDirectory: directory);
        final tags = List<TodoTag>.generate(
          tagCount,
          (index) => TodoTag(
            id: 'tag-$index',
            name: 'Tag $index',
            colorValue: 0xFF20BFB2 + index,
            createdAt: createdAt,
          ),
          growable: false,
        );
        final todos = List<TodoItem>.generate(
          itemCount,
          (index) => TodoItem(
            id: 'todo-$index',
            title: 'Todo item $index',
            content: 'Benchmark notes for todo item $index.',
            createdAt: createdAt.add(Duration(seconds: index)),
          ),
          growable: false,
        );
        final workspace = TagWorkspace(
          tags: tags,
          assignments: <String, Iterable<String>>{
            for (var index = 0; index < itemCount; index++)
              'todo-$index': <String>[
                'tag-${index % tagCount}',
                'tag-${(index + 1) % tagCount}',
              ],
          },
        );

        final todoSave = Stopwatch()..start();
        await todoRepository.save(todos);
        todoSave.stop();

        final tagSave = Stopwatch()..start();
        await tagRepository.save(workspace);
        tagSave.stop();

        final controller = TodoViewModel(
          todoRepository: todoRepository,
          tagRepository: tagRepository,
        );
        final loadAndIndex = Stopwatch()..start();
        await controller.load();
        loadAndIndex.stop();

        final query = 'item ${itemCount - 1}';
        final coldSearch = Stopwatch()..start();
        final searchResults = controller.itemsForView(
          archived: false,
          query: query,
        );
        coldSearch.stop();
        expect(searchResults.single.id, 'todo-${itemCount - 1}');

        final cachedSearch = Stopwatch()..start();
        final cachedResults = controller.itemsForView(
          archived: false,
          query: query,
        );
        cachedSearch.stop();
        expect(identical(searchResults, cachedResults), isTrue);

        final tagFilter = Stopwatch()..start();
        final filteredResults = controller.itemsForView(
          archived: false,
          query: '',
          selectedTagIds: const <String>{'tag-0', 'tag-1'},
        );
        tagFilter.stop();
        expect(filteredResults, isNotEmpty);

        final todoBytes = await File(todoRepository.storagePath).length();
        final tagBytes = await File(tagRepository.storagePath).length();
        debugPrint(
          '$itemCount,'
          '${_milliseconds(todoSave)},'
          '${_milliseconds(tagSave)},'
          '${_milliseconds(loadAndIndex)},'
          '${_milliseconds(coldSearch)},'
          '${_milliseconds(cachedSearch)},'
          '${_milliseconds(tagFilter)},'
          '$todoBytes,'
          '$tagBytes',
        );
      } finally {
        await directory.delete(recursive: true);
      }
    }
  });
}

String _milliseconds(Stopwatch stopwatch) {
  return (stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(3);
}
