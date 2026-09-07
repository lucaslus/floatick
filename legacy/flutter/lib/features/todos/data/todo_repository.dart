import 'dart:convert';
import 'dart:io';

import '../../../core/storage/storage_failure.dart';
import '../domain/todo_item.dart';

abstract interface class TodoRepository {
  String get storagePath;

  Future<List<TodoItem>> load();

  Future<void> save(List<TodoItem> items);
}

class LocalTodoRepository implements TodoRepository {
  LocalTodoRepository({Directory? rootDirectory})
    : rootDirectory = rootDirectory ?? _defaultRootDirectory();

  static const directoryName = '.floatick';
  static const fileName = 'todos.json';

  final Directory rootDirectory;

  File get _storageFile => File('${rootDirectory.path}/$fileName');

  @override
  String get storagePath => _storageFile.path;

  @override
  Future<List<TodoItem>> load() async {
    try {
      await rootDirectory.create(recursive: true);
      if (!await _storageFile.exists()) {
        return <TodoItem>[];
      }

      final decoded = jsonDecode(await _storageFile.readAsString());
      if (decoded is! List<dynamic>) {
        throw const FormatException('Todo storage root must be a JSON array.');
      }

      return decoded
          .map((entry) {
            if (entry is! Map<dynamic, dynamic>) {
              throw const FormatException('Each todo must be a JSON object.');
            }
            return TodoItem.fromJson(Map<String, dynamic>.from(entry));
          })
          .toList(growable: false);
    } on FormatException catch (error) {
      throw StorageFailure(
        kind: StorageFailureKind.invalidData,
        path: storagePath,
        cause: error,
      );
    } on FileSystemException catch (error) {
      throw StorageFailure(
        kind: StorageFailureKind.read,
        path: storagePath,
        cause: error,
      );
    }
  }

  @override
  Future<void> save(List<TodoItem> items) async {
    final temporaryFile = File(
      '${_storageFile.path}.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      await rootDirectory.create(recursive: true);
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(items.map((item) => item.toJson()).toList(growable: false));
      await temporaryFile.writeAsString('$encoded\n', flush: true);
      await temporaryFile.rename(_storageFile.path);
    } on FileSystemException catch (error) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      throw StorageFailure(
        kind: StorageFailureKind.write,
        path: storagePath,
        cause: error,
      );
    }
  }

  static Directory _defaultRootDirectory() {
    final homeDirectory = Platform.environment['HOME'];
    if (homeDirectory == null || homeDirectory.trim().isEmpty) {
      throw const StorageFailure(
        kind: StorageFailureKind.homeDirectoryUnavailable,
      );
    }
    return Directory('$homeDirectory/$directoryName');
  }
}
