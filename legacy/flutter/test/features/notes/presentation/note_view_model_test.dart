import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/notes/data/note_repository.dart';
import 'package:floatick/features/notes/domain/note_item.dart';
import 'package:floatick/features/notes/presentation/note_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'blank drafts are ignored and content-only notes stay untitled',
    () async {
      final repository = _MemoryNoteRepository();
      final controller = NoteViewModel(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 3, 8),
        idGenerator: () => 'note-1',
      );
      await controller.load();

      expect(await controller.save(title: ' ', content: '\n  '), isNull);
      expect(repository.saveCount, 0);

      final created = await controller.save(
        title: '',
        content: '## Today insight\n\nKeep capture friction low.',
      );

      expect(created?.title, NoteViewModel.untitledFallback);
      expect(controller.activeCount, 1);
      expect(repository.saveCount, 1);
    },
  );

  test('active notes put pinned items first and search full content', () async {
    final repository = _MemoryNoteRepository(
      initialItems: <NoteItem>[
        _note('older', title: 'Older', hour: 8, pinned: true),
        _note('newer', title: 'Newer', content: 'server command', hour: 10),
      ],
    );
    final controller = NoteViewModel(repository: repository);
    await controller.load();

    expect(
      controller
          .itemsForView(archived: false, query: '')
          .map((item) => item.id),
      <String>['older', 'newer'],
    );
    expect(
      controller
          .itemsForView(archived: false, query: 'SERVER')
          .map((item) => item.id),
      <String>['newer'],
    );
  });

  test(
    'archive clears pin and archived notes can restore then delete',
    () async {
      var now = DateTime.utc(2026, 8, 3, 12);
      final repository = _MemoryNoteRepository(
        initialItems: <NoteItem>[
          _note('note-1', title: 'Pinned', hour: 8, pinned: true),
        ],
      );
      final controller = NoteViewModel(
        repository: repository,
        clock: () => now,
      );
      await controller.load();

      expect(await controller.archive('note-1'), isTrue);
      expect(controller.itemById('note-1')?.isArchived, isTrue);
      expect(controller.itemById('note-1')?.isPinned, isFalse);

      now = DateTime.utc(2026, 8, 3, 13);
      expect(await controller.restore('note-1'), isTrue);
      expect(controller.itemById('note-1')?.isArchived, isFalse);
      expect(await controller.deletePermanently('note-1'), isFalse);

      await controller.archive('note-1');
      expect(await controller.deletePermanently('note-1'), isTrue);
      expect(controller.items, isEmpty);
    },
  );

  test('storage failure keeps the previous in-memory note', () async {
    final existing = _note('note-1', title: 'Original', hour: 8);
    final repository = _MemoryNoteRepository(
      initialItems: <NoteItem>[existing],
    );
    final controller = NoteViewModel(
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 3, 12),
    );
    await controller.load();
    repository.failSaves = true;

    expect(
      await controller.save(id: 'note-1', title: 'Changed', content: ''),
      isNull,
    );
    expect(controller.itemById('note-1'), existing);
    expect(controller.error?.kind, StorageFailureKind.write);
  });

  test('clearing an existing draft uses the untitled fallback', () async {
    final existing = _note('note-1', title: 'Keep this title', hour: 8);
    final repository = _MemoryNoteRepository(
      initialItems: <NoteItem>[existing],
    );
    final controller = NoteViewModel(
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 3, 12),
    );
    await controller.load();

    final saved = await controller.save(
      id: existing.id,
      title: '',
      content: '',
    );

    expect(saved?.title, NoteViewModel.untitledFallback);
    expect(saved?.content, isEmpty);
  });

  test('note tags persist, filter, count, and are removed globally', () async {
    final repository = _MemoryNoteRepository(
      initialItems: <NoteItem>[
        _note(
          'tagged',
          title: 'Tagged note',
          hour: 8,
          tagIds: const <String>['tag-work'],
        ),
        _note('plain', title: 'Plain note', hour: 9),
      ],
    );
    final controller = NoteViewModel(repository: repository);
    await controller.load();

    expect(
      controller
          .itemsForView(
            archived: false,
            query: '',
            selectedTagIds: const <String>['tag-work'],
          )
          .map((item) => item.id),
      <String>['tagged'],
    );
    expect(controller.tagUsageCountsFor(const <String>['tag-work']), {
      'tag-work': 1,
    });

    final updated = await controller.save(
      id: 'plain',
      title: 'Plain note',
      content: '',
      tagIds: const <String>['tag-work'],
    );
    expect(updated?.tagIds, <String>['tag-work']);
    expect(repository.items.last.tagIds, <String>['tag-work']);
    expect(controller.tagUsageCountsFor(const <String>['tag-work']), {
      'tag-work': 2,
    });

    expect(await controller.removeTag('tag-work'), isTrue);
    expect(controller.items.every((item) => item.tagIds.isEmpty), isTrue);
    expect(controller.tagUsageCountsFor(const <String>['tag-work']), {
      'tag-work': 0,
    });
  });
}

NoteItem _note(
  String id, {
  required String title,
  String content = '',
  required int hour,
  bool pinned = false,
  List<String> tagIds = const <String>[],
}) {
  final timestamp = DateTime.utc(2026, 8, 3, hour);
  return NoteItem(
    id: id,
    title: title,
    content: content,
    createdAt: timestamp,
    updatedAt: timestamp,
    tagIds: tagIds,
    pinnedAt: pinned ? timestamp : null,
  );
}

class _MemoryNoteRepository implements NoteRepository {
  _MemoryNoteRepository({List<NoteItem> initialItems = const <NoteItem>[]})
    : items = List<NoteItem>.of(initialItems);

  List<NoteItem> items;
  bool failSaves = false;
  int saveCount = 0;

  @override
  String get storagePath => '/tmp/floatick-note-view-model-test/notes.json';

  @override
  Future<List<NoteItem>> load() async => List<NoteItem>.of(items);

  @override
  Future<void> save(List<NoteItem> items) async {
    saveCount += 1;
    if (failSaves) {
      throw StorageFailure(kind: StorageFailureKind.write, path: storagePath);
    }
    this.items = List<NoteItem>.of(items);
  }
}
