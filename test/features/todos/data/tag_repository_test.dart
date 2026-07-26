import 'dart:convert';
import 'dart:io';

import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late LocalTagRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'floatick-tag-repository-test-',
    );
    repository = LocalTagRepository(
      rootDirectory: Directory('${temporaryDirectory.path}/.floatick'),
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('missing storage returns an empty tag workspace', () async {
    final workspace = await repository.load();

    expect(workspace.tags, isEmpty);
    expect(workspace.assignments, isEmpty);
    expect(await repository.rootDirectory.exists(), isTrue);
  });

  test('save and load preserve tags and todo assignments', () async {
    final workspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-work',
          name: 'Work',
          colorValue: 0xFF20B8A8,
          createdAt: DateTime.utc(2026, 7, 25, 5),
        ),
      ],
      assignments: const <String, List<String>>{
        'todo-1': <String>['tag-work'],
      },
    );

    await repository.save(workspace);
    final loadedWorkspace = await repository.load();
    final json =
        jsonDecode(await File(repository.storagePath).readAsString())
            as Map<String, dynamic>;

    expect(loadedWorkspace.tags, workspace.tags);
    expect(loadedWorkspace.tagIdsForTodo('todo-1'), <String>['tag-work']);
    expect(json['version'], 1);
    expect(json['assignments'], <String, dynamic>{
      'todo-1': <dynamic>['tag-work'],
    });
  });

  test('damaged tag storage is reported and left unchanged', () async {
    await repository.rootDirectory.create(recursive: true);
    final file = File(repository.storagePath);
    const damagedContent = '{"version": 1, "tags": "invalid"}';
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
