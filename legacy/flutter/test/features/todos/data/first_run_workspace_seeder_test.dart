import 'dart:convert';
import 'dart:io';

import 'package:floatick/features/todos/data/first_run_workspace_seeder.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory storageDirectory;
  late LocalTodoRepository todoRepository;
  late LocalTagRepository tagRepository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'floatick-first-run-seeder-test-',
    );
    storageDirectory = Directory('${temporaryDirectory.path}/.floatick');
    todoRepository = LocalTodoRepository(rootDirectory: storageDirectory);
    tagRepository = LocalTagRepository(rootDirectory: storageDirectory);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'seeds two localized todos with one tag each on first install',
    () async {
      final seeded = await FirstRunWorkspaceSeeder(
        todoRepository: todoRepository,
        tagRepository: tagRepository,
        languageCode: 'zh-CN',
        clock: () => DateTime.utc(2026, 7, 28, 8),
      ).seedIfNeeded();

      final todos = await todoRepository.load();
      final workspace = await tagRepository.load();

      expect(seeded, isTrue);
      expect(todos, hasLength(2));
      expect(todos.map((todo) => todo.title), <String>[
        '欢迎使用 Floatick',
        '试试完成这条待办',
      ]);
      expect(todos.every((todo) => todo.content.isNotEmpty), isTrue);
      expect(workspace.tags.map((tag) => tag.name), <String>['欢迎', '快速上手']);
      expect(
        todos.map((todo) => workspace.tagIdsForTodo(todo.id).length),
        everyElement(1),
      );
    },
  );

  test('uses English copy for non-Chinese system languages', () async {
    await FirstRunWorkspaceSeeder(
      todoRepository: todoRepository,
      tagRepository: tagRepository,
      languageCode: 'en-US',
      clock: () => DateTime.utc(2026, 7, 28, 8),
    ).seedIfNeeded();

    final todos = await todoRepository.load();
    final workspace = await tagRepository.load();

    expect(todos.map((todo) => todo.title), <String>[
      'Welcome to Floatick',
      'Try completing this todo',
    ]);
    expect(workspace.tags.map((tag) => tag.name), <String>[
      'Welcome',
      'Start here',
    ]);
  });

  test('does not reseed after a user deliberately clears all todos', () async {
    await storageDirectory.create(recursive: true);
    await File(
      todoRepository.storagePath,
    ).writeAsString(jsonEncode(<Object?>[]));

    final seeded = await FirstRunWorkspaceSeeder(
      todoRepository: todoRepository,
      tagRepository: tagRepository,
      languageCode: 'zh-CN',
    ).seedIfNeeded();

    expect(seeded, isFalse);
    expect(await todoRepository.load(), isEmpty);
    expect(await File(tagRepository.storagePath).exists(), isFalse);
  });

  test('does not seed over an existing tag workspace', () async {
    await tagRepository.save(await tagRepository.load());

    final seeded = await FirstRunWorkspaceSeeder(
      todoRepository: todoRepository,
      tagRepository: tagRepository,
      languageCode: 'zh-CN',
    ).seedIfNeeded();

    expect(seeded, isFalse);
    expect(await File(todoRepository.storagePath).exists(), isFalse);
  });
}
