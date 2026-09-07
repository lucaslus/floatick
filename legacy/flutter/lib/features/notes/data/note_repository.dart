import 'dart:convert';
import 'dart:io';

import '../../../core/storage/storage_failure.dart';
import '../../todos/data/todo_repository.dart';
import '../domain/note_item.dart';

abstract interface class NoteRepository {
  String get storagePath;

  Future<List<NoteItem>> load();

  Future<void> save(List<NoteItem> items);
}

class LocalNoteRepository implements NoteRepository {
  LocalNoteRepository({Directory? rootDirectory})
    : rootDirectory =
          rootDirectory ?? Directory(_defaultStorageDirectoryPath());

  static const fileName = 'notes.json';

  final Directory rootDirectory;

  File get _storageFile => File('${rootDirectory.path}/$fileName');

  @override
  String get storagePath => _storageFile.path;

  @override
  Future<List<NoteItem>> load() async {
    try {
      await rootDirectory.create(recursive: true);
      if (!await _storageFile.exists()) {
        return <NoteItem>[];
      }

      final decoded = jsonDecode(await _storageFile.readAsString());
      if (decoded is! List<dynamic>) {
        throw const FormatException('Note storage root must be a JSON array.');
      }
      final items = decoded
          .map((entry) {
            if (entry is! Map<dynamic, dynamic>) {
              throw const FormatException('Each note must be a JSON object.');
            }
            return NoteItem.fromJson(Map<String, dynamic>.from(entry));
          })
          .toList(growable: false);
      if (items.map((item) => item.id).toSet().length != items.length) {
        throw const FormatException('Note ids must be unique.');
      }
      return items;
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
  Future<void> save(List<NoteItem> items) async {
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

  static String _defaultStorageDirectoryPath() {
    final homeDirectory = Platform.environment['HOME'];
    if (homeDirectory == null || homeDirectory.trim().isEmpty) {
      throw const StorageFailure(
        kind: StorageFailureKind.homeDirectoryUnavailable,
      );
    }
    return '$homeDirectory/${LocalTodoRepository.directoryName}';
  }
}
