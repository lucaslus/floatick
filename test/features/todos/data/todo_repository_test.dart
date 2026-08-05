import 'dart:convert';
import 'dart:io';

import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late LocalTodoRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'floatick-repository-test-',
    );
    repository = LocalTodoRepository(
      rootDirectory: Directory('${temporaryDirectory.path}/.floatick'),
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'missing storage creates the directory and returns an empty list',
    () async {
      final items = await repository.load();

      expect(items, isEmpty);
      expect(await repository.rootDirectory.exists(), isTrue);
    },
  );

  test('save and load preserve the Swift-compatible JSON schema', () async {
    final item = TodoItem(
      id: 'todo-1',
      title: 'Finish the Flutter shell',
      content: '## Notes\n\n- Keep it **fast**.',
      createdAt: DateTime.utc(2026, 7, 23, 6, 30),
      startedAt: DateTime.utc(2026, 7, 23, 6, 45),
      completedAt: DateTime.utc(2026, 7, 23, 7),
    );

    await repository.save(<TodoItem>[item]);
    final loadedItems = await repository.load();
    final json = jsonDecode(await File(repository.storagePath).readAsString());

    expect(loadedItems, <TodoItem>[item]);
    expect(json, <Object?>[
      <String, Object?>{
        'id': 'todo-1',
        'title': 'Finish the Flutter shell',
        'content': '## Notes\n\n- Keep it **fast**.',
        'createdAt': '2026-07-23T06:30:00.000Z',
        'startedAt': '2026-07-23T06:45:00.000Z',
        'completedAt': '2026-07-23T07:00:00.000Z',
      },
    ]);
  });

  test('legacy items without content load with empty content', () async {
    await repository.rootDirectory.create(recursive: true);
    await File(repository.storagePath).writeAsString(
      jsonEncode(<Object?>[
        <String, Object?>{
          'id': 'legacy',
          'title': 'Existing todo',
          'createdAt': '2026-07-23T06:30:00.000Z',
        },
      ]),
    );

    final item = (await repository.load()).single;

    expect(item.title, 'Existing todo');
    expect(item.content, isEmpty);
    expect(item.startedAt, isNull);
    expect(item.isDoing, isFalse);
  });

  test('damaged storage is reported and left unchanged', () async {
    await repository.rootDirectory.create(recursive: true);
    final file = File(repository.storagePath);
    const damagedContent = '{"not": "a todo list"}';
    await file.writeAsString(damagedContent);

    await expectLater(
      repository.load(),
      throwsA(
        isA<StorageFailure>().having(
          (error) => error.kind,
          'kind',
          StorageFailureKind.invalidData,
        ),
      ),
    );
    expect(await file.readAsString(), damagedContent);
  });
}
