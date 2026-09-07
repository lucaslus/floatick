import 'dart:io';

import '../../../core/storage/storage_failure.dart';
import '../domain/tag_workspace.dart';
import '../domain/todo_item.dart';
import '../domain/todo_tag.dart';
import 'tag_repository.dart';
import 'todo_repository.dart';

class FirstRunWorkspaceSeeder {
  FirstRunWorkspaceSeeder({
    required LocalTodoRepository todoRepository,
    required LocalTagRepository tagRepository,
    required String languageCode,
    DateTime Function()? clock,
  }) : // Public named parameters cannot use the private field identifiers.
       // ignore: prefer_initializing_formals
       _todoRepository = todoRepository,
       // ignore: prefer_initializing_formals
       _tagRepository = tagRepository,
       _copy = _WelcomeCopy.forLanguageCode(languageCode),
       _clock = clock ?? DateTime.now;

  static const _welcomeTodoId = 'floatick-welcome-todo';
  static const _tryTodoId = 'floatick-try-todo';
  static const _welcomeTagId = 'floatick-welcome-tag';
  static const _tryTagId = 'floatick-try-tag';
  static const _welcomeTagColor = 0xFF20B8A8;
  static const _tryTagColor = 0xFF4C8FF5;

  final LocalTodoRepository _todoRepository;
  final LocalTagRepository _tagRepository;
  final _WelcomeCopy _copy;
  final DateTime Function() _clock;

  Future<bool> seedIfNeeded() async {
    final todoStorage = File(_todoRepository.storagePath);
    final tagStorage = File(_tagRepository.storagePath);

    try {
      final storageAlreadyExists =
          await todoStorage.exists() || await tagStorage.exists();
      if (storageAlreadyExists) {
        return false;
      }
    } on FileSystemException catch (error) {
      throw StorageFailure(
        kind: StorageFailureKind.read,
        path: _todoRepository.rootDirectory.path,
        cause: error,
      );
    }

    final now = _clock();
    final items = <TodoItem>[
      TodoItem(
        id: _welcomeTodoId,
        title: _copy.welcomeTitle,
        content: _copy.welcomeContent,
        createdAt: now,
      ),
      TodoItem(
        id: _tryTodoId,
        title: _copy.tryTitle,
        content: _copy.tryContent,
        createdAt: now.subtract(const Duration(minutes: 1)),
      ),
    ];
    final workspace = TagWorkspace(
      tags: <TodoTag>[
        TodoTag(
          id: _welcomeTagId,
          name: _copy.welcomeTag,
          colorValue: _welcomeTagColor,
          createdAt: now,
        ),
        TodoTag(
          id: _tryTagId,
          name: _copy.tryTag,
          colorValue: _tryTagColor,
          createdAt: now,
        ),
      ],
      assignments: const <String, List<String>>{
        _welcomeTodoId: <String>[_welcomeTagId],
        _tryTodoId: <String>[_tryTagId],
      },
    );

    try {
      await _tagRepository.save(workspace);
      await _todoRepository.save(items);
      return true;
    } on StorageFailure catch (error, stackTrace) {
      await _removePartialSeed(todoStorage, tagStorage);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _removePartialSeed(File todoStorage, File tagStorage) async {
    try {
      for (final file in <File>[todoStorage, tagStorage]) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } on FileSystemException catch (error) {
      throw StorageFailure(
        kind: StorageFailureKind.write,
        path: _todoRepository.rootDirectory.path,
        cause: error,
      );
    }
  }
}

class _WelcomeCopy {
  const _WelcomeCopy({
    required this.welcomeTitle,
    required this.welcomeContent,
    required this.welcomeTag,
    required this.tryTitle,
    required this.tryContent,
    required this.tryTag,
  });

  factory _WelcomeCopy.forLanguageCode(String languageCode) {
    if (languageCode.toLowerCase().startsWith('zh')) {
      return const _WelcomeCopy(
        welcomeTitle: '欢迎使用 Floatick',
        welcomeContent: '点击「+ 新建」创建第一条待办，再用标签把它整理得井井有条。',
        welcomeTag: '欢迎',
        tryTitle: '试试完成这条待办',
        tryContent: '双击待办查看详情；将鼠标悬浮到待办上，可以编辑或归档，完成后试着勾选它。',
        tryTag: '快速上手',
      );
    }
    return const _WelcomeCopy(
      welcomeTitle: 'Welcome to Floatick',
      welcomeContent:
          'Choose “+ New” to create your first todo, then use tags to keep it organized.',
      welcomeTag: 'Welcome',
      tryTitle: 'Try completing this todo',
      tryContent:
          'Double-click a todo for details. Hover over it to edit or archive it, then check it off.',
      tryTag: 'Start here',
    );
  }

  final String welcomeTitle;
  final String welcomeContent;
  final String welcomeTag;
  final String tryTitle;
  final String tryContent;
  final String tryTag;
}
