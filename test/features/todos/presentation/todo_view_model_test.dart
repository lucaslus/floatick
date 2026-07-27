import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const firstDate = '2026-07-23T02:00:00.000Z';
  late _MemoryTodoRepository repository;
  late _MemoryTagRepository tagRepository;
  late TodoViewModel controller;
  late int idSequence;

  setUp(() {
    repository = _MemoryTodoRepository();
    tagRepository = _MemoryTagRepository();
    idSequence = 0;
    controller = TodoViewModel(
      todoRepository: repository,
      tagRepository: tagRepository,
      clock: () => DateTime.parse(firstDate),
      idGenerator: () => 'todo-${++idSequence}',
    );
  });

  test('add trims the title and persists before exposing state', () async {
    await controller.load();
    final didAdd = await controller.add(
      '  Write focused tests  ',
      content: '# Coverage\n\n- Storage\n- UI',
    );

    expect(didAdd, isTrue);
    expect(controller.items.single.title, 'Write focused tests');
    expect(controller.items.single.content, '# Coverage\n\n- Storage\n- UI');
    expect(controller.items.single.createdAt, DateTime.parse(firstDate));
    expect(repository.savedItems, controller.items);
    expect(controller.activeCount, 1);
  });

  test('blank titles are ignored', () async {
    await controller.load();
    final didAdd = await controller.add('   ', content: 'Not enough');

    expect(didAdd, isFalse);
    expect(controller.items, isEmpty);
    expect(repository.saveCount, 0);
  });

  test('duplicate generated ids are rejected without persisting', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'todo-1',
        title: 'Existing todo',
        createdAt: DateTime.parse(firstDate),
      ),
    ];
    await controller.load();

    final didAdd = await controller.add('Conflicting todo');

    expect(didAdd, isFalse);
    expect(controller.items.single.title, 'Existing todo');
    expect(repository.saveCount, 0);
  });

  test(
    'itemsForView searches visible titles, ignores content, and sorts',
    () async {
      repository.savedItems = <TodoItem>[
        TodoItem(
          id: 'older-active',
          title: 'Write architecture notes',
          content: 'Document the local storage format.',
          createdAt: DateTime.parse('2026-07-21T12:00:00.000Z'),
        ),
        TodoItem(
          id: 'newer-active',
          title: 'Polish release workflow',
          createdAt: DateTime.parse('2026-07-23T12:00:00.000Z'),
        ),
        TodoItem(
          id: 'archived',
          title: 'Archived architecture draft',
          createdAt: DateTime.parse('2026-07-20T12:00:00.000Z'),
          archivedAt: DateTime.parse('2026-07-24T12:00:00.000Z'),
        ),
      ];
      await controller.load();

      expect(
        controller
            .itemsForView(archived: false, query: '')
            .map((item) => item.id),
        <String>['newer-active', 'older-active'],
      );
      expect(
        controller
            .itemsForView(archived: false, query: 'ARCHITECTURE')
            .map((item) => item.id),
        <String>['older-active'],
      );
      expect(
        controller
            .itemsForView(archived: false, query: 'storage format')
            .map((item) => item.id),
        isEmpty,
      );
      expect(
        controller.itemsForView(archived: true, query: '').single.id,
        'archived',
      );
    },
  );

  test('rename trims and persists the updated title', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'existing',
        title: 'Original title',
        createdAt: DateTime.parse(firstDate),
      ),
    ];
    await controller.load();

    final didRename = await controller.rename('existing', '  Updated title  ');

    expect(didRename, isTrue);
    expect(controller.items.single.title, 'Updated title');
    expect(repository.savedItems.single.title, 'Updated title');
    expect(repository.saveCount, 1);
  });

  test('rename rejects blank or missing items without persisting', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'existing',
        title: 'Original title',
        createdAt: DateTime.parse(firstDate),
      ),
    ];
    await controller.load();

    expect(await controller.rename('existing', '   '), isFalse);
    expect(await controller.rename('missing', 'Updated title'), isFalse);
    expect(controller.items.single.title, 'Original title');
    expect(repository.saveCount, 0);
  });

  test('updateDetails persists title and markdown content together', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'existing',
        title: 'Original title',
        content: 'Original content',
        createdAt: DateTime.parse(firstDate),
      ),
    ];
    await controller.load();

    final didUpdate = await controller.updateDetails(
      id: 'existing',
      title: '  Updated title  ',
      content: '## Notes\n\n`done`',
    );

    expect(didUpdate, isTrue);
    expect(controller.items.single.title, 'Updated title');
    expect(controller.items.single.content, '## Notes\n\n`done`');
    expect(repository.savedItems.single, controller.items.single);
  });

  test('updateDetails rejects blank titles and keeps existing data', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'existing',
        title: 'Original title',
        content: 'Original content',
        createdAt: DateTime.parse(firstDate),
      ),
    ];
    await controller.load();

    final didUpdate = await controller.updateDetails(
      id: 'existing',
      title: ' ',
      content: 'Changed content',
    );

    expect(didUpdate, isFalse);
    expect(controller.items.single.title, 'Original title');
    expect(controller.items.single.content, 'Original content');
    expect(repository.saveCount, 0);
  });

  test('a failed rename keeps the original title', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'existing',
        title: 'Original title',
        createdAt: DateTime.parse(firstDate),
      ),
    ];
    await controller.load();
    repository.failNextSave = true;

    final didRename = await controller.rename('existing', 'Updated title');

    expect(didRename, isFalse);
    expect(controller.items.single.title, 'Original title');
    expect(controller.error?.kind, StorageFailureKind.write);
  });

  test(
    'completion, archive, and restore share one persisted state flow',
    () async {
      repository.savedItems = <TodoItem>[
        TodoItem(
          id: 'existing',
          title: 'Ship it',
          createdAt: DateTime.parse(firstDate),
        ),
      ];
      await controller.load();

      await controller.toggleCompletion('existing');
      expect(controller.items.single.isCompleted, isTrue);
      expect(controller.activeCount, 0);

      await controller.archive('existing');
      expect(controller.items.single.isArchived, isTrue);
      expect(controller.archivedCount, 1);

      await controller.restore('existing');
      expect(controller.items.single.isArchived, isFalse);
      expect(controller.archivedCount, 0);
      expect(repository.saveCount, 3);
    },
  );

  test('archived todos reject detail and tag edits', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'archived',
        title: 'Archived todo',
        content: 'Original notes',
        createdAt: DateTime.parse(firstDate),
        archivedAt: DateTime.parse('2026-07-24T12:00:00.000Z'),
      ),
    ];
    tagRepository.savedWorkspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-focus',
          name: 'Focus',
          colorValue: 0xFF4C8FF5,
          createdAt: DateTime.parse(firstDate),
        ),
      ],
      assignments: const <String, List<String>>{},
    );
    await controller.load();

    expect(await controller.rename('archived', 'Changed'), isFalse);
    expect(
      await controller.updateDetails(
        id: 'archived',
        title: 'Changed',
        content: 'Changed notes',
        tagIds: const <String>['tag-focus'],
      ),
      isFalse,
    );
    expect(
      await controller.toggleTagForTodo(todoId: 'archived', tagId: 'tag-focus'),
      isFalse,
    );
    await controller.toggleCompletion('archived');

    expect(controller.items.single.title, 'Archived todo');
    expect(controller.items.single.content, 'Original notes');
    expect(controller.items.single.isCompleted, isFalse);
    expect(controller.tagIdsForTodo('archived'), isEmpty);
    expect(repository.saveCount, 0);
    expect(tagRepository.saveCount, 0);
  });

  test('permanent delete only removes archived todo and its tags', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'active',
        title: 'Active todo',
        createdAt: DateTime.parse(firstDate),
      ),
      TodoItem(
        id: 'archived',
        title: 'Archived todo',
        createdAt: DateTime.parse(firstDate),
        archivedAt: DateTime.parse('2026-07-24T12:00:00.000Z'),
      ),
    ];
    tagRepository.savedWorkspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-focus',
          name: 'Focus',
          colorValue: 0xFF4C8FF5,
          createdAt: DateTime.parse(firstDate),
        ),
      ],
      assignments: const <String, List<String>>{
        'active': <String>['tag-focus'],
        'archived': <String>['tag-focus'],
      },
    );
    await controller.load();

    expect(await controller.deletePermanently('active'), isFalse);
    expect(await controller.deletePermanently('archived'), isTrue);

    expect(controller.items.map((item) => item.id), <String>['active']);
    expect(controller.tagIdsForTodo('active'), <String>['tag-focus']);
    expect(controller.tagIdsForTodo('archived'), isEmpty);
    expect(repository.savedItems.map((item) => item.id), <String>['active']);
    expect(tagRepository.savedWorkspace.assignments, <String, List<String>>{
      'active': <String>['tag-focus'],
    });
    expect(repository.saveCount, 1);
    expect(tagRepository.saveCount, 1);
  });

  test('failed tag cleanup rolls back permanent deletion', () async {
    final archivedItem = TodoItem(
      id: 'archived',
      title: 'Archived todo',
      createdAt: DateTime.parse(firstDate),
      archivedAt: DateTime.parse('2026-07-24T12:00:00.000Z'),
    );
    repository.savedItems = <TodoItem>[archivedItem];
    tagRepository.savedWorkspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-focus',
          name: 'Focus',
          colorValue: 0xFF4C8FF5,
          createdAt: DateTime.parse(firstDate),
        ),
      ],
      assignments: const <String, List<String>>{
        'archived': <String>['tag-focus'],
      },
    );
    await controller.load();
    tagRepository.failNextSave = true;

    expect(await controller.deletePermanently('archived'), isFalse);

    expect(controller.items, <TodoItem>[archivedItem]);
    expect(repository.savedItems, <TodoItem>[archivedItem]);
    expect(controller.tagIdsForTodo('archived'), <String>['tag-focus']);
    expect(controller.error?.kind, StorageFailureKind.write);
    expect(repository.saveCount, 2);
    expect(tagRepository.saveCount, 1);
  });

  test('a failed rollback completes the original save when possible', () async {
    tagRepository.savedWorkspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-focus',
          name: 'Focus',
          colorValue: 0xFF4C8FF5,
          createdAt: DateTime.parse(firstDate),
        ),
      ],
      assignments: const <String, List<String>>{},
    );
    await controller.load();
    repository.saveCallsToFail.add(2);
    tagRepository.failNextSave = true;

    final didAdd = await controller.add(
      'Recovered todo',
      tagIds: const <String>['tag-focus'],
    );

    expect(didAdd, isTrue);
    expect(controller.items.single.title, 'Recovered todo');
    expect(controller.tagIdsForTodo(controller.items.single.id), <String>[
      'tag-focus',
    ]);
    expect(repository.saveCount, 2);
    expect(tagRepository.saveCount, 2);
    expect(controller.error, isNull);
  });

  test(
    'an unrecoverable partial save never reports a successful add',
    () async {
      tagRepository.savedWorkspace = TagWorkspace(
        tags: <TodoTag>[
          TodoTag(
            id: 'tag-focus',
            name: 'Focus',
            colorValue: 0xFF4C8FF5,
            createdAt: DateTime.parse(firstDate),
          ),
        ],
        assignments: const <String, List<String>>{},
      );
      await controller.load();
      repository.saveCallsToFail.add(2);
      tagRepository.saveCallsToFail.addAll(<int>{1, 2});

      final didAdd = await controller.add(
        'Partially persisted todo',
        tagIds: const <String>['tag-focus'],
      );

      expect(didAdd, isFalse);
      expect(repository.savedItems.single.title, 'Partially persisted todo');
      expect(controller.items, repository.savedItems);
      expect(
        controller.tagIdsForTodo(repository.savedItems.single.id),
        isEmpty,
      );
      expect(controller.error?.kind, StorageFailureKind.write);
      expect(repository.saveCount, 2);
    },
  );

  test(
    'a failed save keeps visible state unchanged and queue usable',
    () async {
      await controller.load();
      repository.failNextSave = true;

      await controller.add('Will fail');

      expect(controller.items, isEmpty);
      expect(controller.error?.kind, StorageFailureKind.write);

      await controller.add('Will succeed');

      expect(controller.items.single.title, 'Will succeed');
      expect(controller.error, isNull);
    },
  );

  test(
    'tag CRUD enforces names, colors, and case-insensitive uniqueness',
    () async {
      await controller.load();

      expect(
        await controller.createTag(name: '  Work  ', colorValue: 0xFF20B8A8),
        TagMutationResult.success,
      );
      expect(controller.tags.single.name, 'Work');
      expect(
        await controller.createTag(name: 'work', colorValue: 0xFF4C8FF5),
        TagMutationResult.duplicateName,
      );
      expect(
        await controller.createTag(name: '12345678901', colorValue: 0xFF4C8FF5),
        TagMutationResult.nameTooLong,
      );

      final tagId = controller.tags.single.id;
      expect(
        await controller.updateTag(
          id: tagId,
          name: 'Focus',
          colorValue: 0xFF4C8FF5,
        ),
        TagMutationResult.success,
      );
      expect(controller.tags.single.name, 'Focus');
      expect(controller.tags.single.colorValue, 0xFF4C8FF5);

      expect(await controller.deleteTag(tagId), TagMutationResult.success);
      expect(controller.tags, isEmpty);
    },
  );

  test(
    'tag assignments persist, filter todos, and are removed on delete',
    () async {
      repository.savedItems = <TodoItem>[
        TodoItem(
          id: 'work-item',
          title: 'Prepare release notes',
          createdAt: DateTime.parse(firstDate),
        ),
        TodoItem(
          id: 'personal-item',
          title: 'Buy coffee',
          createdAt: DateTime.parse(firstDate),
        ),
      ];
      tagRepository.savedWorkspace = TagWorkspace(
        tags: <TodoTag>[
          TodoTag(
            id: 'tag-work',
            name: 'Work',
            colorValue: 0xFF20B8A8,
            createdAt: DateTime.parse(firstDate),
          ),
          TodoTag(
            id: 'tag-personal',
            name: 'Personal',
            colorValue: 0xFF4D8DF7,
            createdAt: DateTime.parse(firstDate),
          ),
        ],
        assignments: const <String, List<String>>{
          'work-item': <String>['tag-work'],
          'personal-item': <String>['tag-personal'],
        },
      );
      await controller.load();

      expect(
        controller
            .itemsForView(
              archived: false,
              query: '',
              selectedTagIds: const <String>{'tag-work'},
            )
            .map((item) => item.id),
        <String>['work-item'],
      );
      expect(
        controller
            .itemsForView(
              archived: false,
              query: '',
              selectedTagIds: const <String>{'tag-work', 'tag-personal'},
            )
            .map((item) => item.id),
        <String>['work-item', 'personal-item'],
      );
      expect(
        controller
            .itemsForView(archived: false, query: 'work')
            .map((item) => item.id),
        <String>['work-item'],
      );

      expect(
        await controller.toggleTagForTodo(
          todoId: 'personal-item',
          tagId: 'tag-work',
        ),
        isTrue,
      );
      expect(controller.tagIdsForTodo('personal-item'), <String>[
        'tag-work',
        'tag-personal',
      ]);
      expect(controller.tagUsageCount('tag-work'), 2);
      expect(
        controller.tagUsageCountsFor(const <String>['tag-work', 'tag-missing']),
        const <String, int>{'tag-work': 2, 'tag-missing': 0},
      );

      await controller.deleteTag('tag-work');
      expect(controller.tags.map((tag) => tag.id), <String>['tag-personal']);
      expect(controller.tagIdsForTodo('work-item'), isEmpty);
      expect(controller.tagIdsForTodo('personal-item'), <String>[
        'tag-personal',
      ]);
    },
  );

  test('failed tag save leaves visible tag state unchanged', () async {
    await controller.load();
    tagRepository.failNextSave = true;

    final result = await controller.createTag(
      name: 'Focus',
      colorValue: 0xFF20B8A8,
    );

    expect(result, TagMutationResult.storageFailure);
    expect(controller.tags, isEmpty);
    expect(controller.error?.kind, StorageFailureKind.write);
  });

  test(
    'failed tag assignment reports failure and keeps state unchanged',
    () async {
      repository.savedItems = <TodoItem>[
        TodoItem(
          id: 'todo-1',
          title: 'Keep assignment stable',
          createdAt: DateTime.parse(firstDate),
        ),
      ];
      tagRepository.savedWorkspace = TagWorkspace(
        tags: <TodoTag>[
          TodoTag(
            id: 'tag-work',
            name: 'Work',
            colorValue: 0xFF20B8A8,
            createdAt: DateTime.parse(firstDate),
          ),
        ],
        assignments: const <String, List<String>>{},
      );
      await controller.load();
      tagRepository.failNextSave = true;

      expect(
        await controller.toggleTagForTodo(todoId: 'todo-1', tagId: 'tag-work'),
        isFalse,
      );
      expect(controller.tagIdsForTodo('todo-1'), isEmpty);
      expect(controller.error?.kind, StorageFailureKind.write);
    },
  );

  test('add persists selected tags with the new todo', () async {
    tagRepository.savedWorkspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-work',
          name: 'Work',
          colorValue: 0xFF20B8A8,
          createdAt: DateTime.parse(firstDate),
        ),
      ],
      assignments: const <String, List<String>>{},
    );
    await controller.load();

    final didAdd = await controller.add(
      'Prepare release',
      tagIds: const <String>['tag-work'],
    );

    expect(didAdd, isTrue);
    expect(controller.items.single.id, 'todo-1');
    expect(controller.tagIdsForTodo('todo-1'), <String>['tag-work']);
    expect(tagRepository.savedWorkspace.tagIdsForTodo('todo-1'), <String>[
      'tag-work',
    ]);
  });

  test('a failed tag save rolls back a newly created todo', () async {
    tagRepository.savedWorkspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-work',
          name: 'Work',
          colorValue: 0xFF20B8A8,
          createdAt: DateTime.parse(firstDate),
        ),
      ],
      assignments: const <String, List<String>>{},
    );
    await controller.load();
    tagRepository.failNextSave = true;

    final didAdd = await controller.add(
      'Prepare release',
      tagIds: const <String>['tag-work'],
    );

    expect(didAdd, isFalse);
    expect(controller.items, isEmpty);
    expect(repository.savedItems, isEmpty);
    expect(controller.error?.kind, StorageFailureKind.write);
  });

  test('updateDetails persists tag-only changes', () async {
    repository.savedItems = <TodoItem>[
      TodoItem(
        id: 'existing',
        title: 'Prepare release',
        createdAt: DateTime.parse(firstDate),
      ),
    ];
    tagRepository.savedWorkspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: 'tag-focus',
          name: 'Focus',
          colorValue: 0xFF4C8FF5,
          createdAt: DateTime.parse(firstDate),
        ),
      ],
      assignments: const <String, List<String>>{},
    );
    await controller.load();

    final didUpdate = await controller.updateDetails(
      id: 'existing',
      title: 'Prepare release',
      content: '',
      tagIds: const <String>['tag-focus'],
    );

    expect(didUpdate, isTrue);
    expect(controller.tagIdsForTodo('existing'), <String>['tag-focus']);
    expect(repository.saveCount, 0);
    expect(tagRepository.saveCount, 1);
  });
}

class _MemoryTodoRepository implements TodoRepository {
  List<TodoItem> savedItems = <TodoItem>[];
  int saveCount = 0;
  bool failNextSave = false;
  final Set<int> saveCallsToFail = <int>{};

  @override
  String get storagePath => '/tmp/floatick-test/todos.json';

  @override
  Future<List<TodoItem>> load() async {
    return List<TodoItem>.of(savedItems);
  }

  @override
  Future<void> save(List<TodoItem> items) async {
    saveCount += 1;
    if (failNextSave || saveCallsToFail.remove(saveCount)) {
      failNextSave = false;
      throw const StorageFailure(kind: StorageFailureKind.write);
    }
    savedItems = List<TodoItem>.of(items);
  }
}

class _MemoryTagRepository implements TagRepository {
  TagWorkspace savedWorkspace = TagWorkspace.empty();
  int saveCount = 0;
  bool failNextSave = false;
  final Set<int> saveCallsToFail = <int>{};

  @override
  String get storagePath => '/tmp/floatick-test/tags.json';

  @override
  Future<TagWorkspace> load() async => savedWorkspace;

  @override
  Future<void> save(TagWorkspace workspace) async {
    saveCount += 1;
    if (failNextSave || saveCallsToFail.remove(saveCount)) {
      failNextSave = false;
      throw const StorageFailure(kind: StorageFailureKind.write);
    }
    savedWorkspace = workspace;
  }
}
