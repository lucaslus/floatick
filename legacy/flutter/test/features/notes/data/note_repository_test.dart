import 'dart:convert';
import 'dart:io';

import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/notes/data/note_repository.dart';
import 'package:floatick/features/notes/domain/note_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late LocalNoteRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'floatick-note-repository-test-',
    );
    repository = LocalNoteRepository(
      rootDirectory: Directory('${temporaryDirectory.path}/.floatick'),
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('missing storage creates the directory and returns no notes', () async {
    expect(await repository.load(), isEmpty);
    expect(await repository.rootDirectory.exists(), isTrue);
  });

  test('save and load preserve note timestamps and state', () async {
    final item = NoteItem(
      id: 'note-1',
      title: 'Weekly review',
      content: '## Completed\n\n- Shipped notes',
      tagIds: const <String>['tag-work'],
      createdAt: DateTime.utc(2026, 8, 3, 8),
      updatedAt: DateTime.utc(2026, 8, 3, 9),
      pinnedAt: DateTime.utc(2026, 8, 3, 9, 5),
    );

    await repository.save(<NoteItem>[item]);

    expect(await repository.load(), <NoteItem>[item]);
    expect(
      jsonDecode(await File(repository.storagePath).readAsString()),
      <Object?>[
        <String, Object?>{
          'id': 'note-1',
          'title': 'Weekly review',
          'content': '## Completed\n\n- Shipped notes',
          'tagIds': <Object?>['tag-work'],
          'createdAt': '2026-08-03T08:00:00.000Z',
          'updatedAt': '2026-08-03T09:00:00.000Z',
          'pinnedAt': '2026-08-03T09:05:00.000Z',
        },
      ],
    );
  });

  test('legacy notes without updatedAt use createdAt', () async {
    await repository.rootDirectory.create(recursive: true);
    await File(repository.storagePath).writeAsString(
      jsonEncode(<Object?>[
        <String, Object?>{
          'id': 'legacy-note',
          'title': 'Legacy',
          'createdAt': '2026-08-03T08:00:00.000Z',
        },
      ]),
    );

    final item = (await repository.load()).single;
    expect(item.updatedAt, item.createdAt);
    expect(item.content, isEmpty);
    expect(item.tagIds, isEmpty);
  });

  test('duplicate ids are reported as invalid data', () async {
    await repository.rootDirectory.create(recursive: true);
    final file = File(repository.storagePath);
    await file.writeAsString(
      jsonEncode(<Object?>[
        <String, Object?>{
          'id': 'duplicate',
          'title': 'One',
          'createdAt': '2026-08-03T08:00:00.000Z',
        },
        <String, Object?>{
          'id': 'duplicate',
          'title': 'Two',
          'createdAt': '2026-08-03T09:00:00.000Z',
        },
      ]),
    );

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
  });
}
