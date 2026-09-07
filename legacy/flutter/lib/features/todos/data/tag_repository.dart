import 'dart:convert';
import 'dart:io';

import '../../../core/storage/storage_failure.dart';
import '../domain/tag_workspace.dart';
import 'todo_repository.dart';

abstract interface class TagRepository {
  String get storagePath;

  Future<TagWorkspace> load();

  Future<void> save(TagWorkspace workspace);
}

class LocalTagRepository implements TagRepository {
  LocalTagRepository({Directory? rootDirectory})
    : rootDirectory = rootDirectory ?? _defaultRootDirectory();

  static const fileName = 'tags.json';

  final Directory rootDirectory;

  File get _storageFile => File('${rootDirectory.path}/$fileName');

  @override
  String get storagePath => _storageFile.path;

  @override
  Future<TagWorkspace> load() async {
    try {
      await rootDirectory.create(recursive: true);
      if (!await _storageFile.exists()) {
        return TagWorkspace.empty();
      }

      final decoded = jsonDecode(await _storageFile.readAsString());
      if (decoded is! Map<dynamic, dynamic>) {
        throw const FormatException('Tag storage root must be a JSON object.');
      }
      return TagWorkspace.fromJson(Map<String, dynamic>.from(decoded));
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
  Future<void> save(TagWorkspace workspace) async {
    final temporaryFile = File(
      '${_storageFile.path}.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      await rootDirectory.create(recursive: true);
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(workspace.toJson());
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
    return Directory('$homeDirectory/${LocalTodoRepository.directoryName}');
  }
}
