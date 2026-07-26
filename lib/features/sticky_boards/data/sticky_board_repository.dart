import 'dart:convert';
import 'dart:io';

import '../../../core/storage/storage_failure.dart';
import '../../todos/data/todo_repository.dart';
import '../domain/sticky_board_workspace.dart';

abstract interface class StickyBoardRepository {
  String get storagePath;

  Future<StickyBoardWorkspace> load();

  Future<void> save(StickyBoardWorkspace workspace);
}

class LocalStickyBoardRepository implements StickyBoardRepository {
  LocalStickyBoardRepository({Directory? rootDirectory})
    : rootDirectory = rootDirectory ?? _defaultRootDirectory();

  static const fileName = 'sticky_boards.json';

  final Directory rootDirectory;

  File get _storageFile => File('${rootDirectory.path}/$fileName');

  @override
  String get storagePath => _storageFile.path;

  @override
  Future<StickyBoardWorkspace> load() async {
    try {
      await rootDirectory.create(recursive: true);
      if (!await _storageFile.exists()) {
        return StickyBoardWorkspace.empty();
      }

      final decoded = jsonDecode(await _storageFile.readAsString());
      if (decoded is! Map<dynamic, dynamic>) {
        throw const FormatException(
          'Sticky board storage root must be a JSON object.',
        );
      }
      return StickyBoardWorkspace.fromJson(Map<String, dynamic>.from(decoded));
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
  Future<void> save(StickyBoardWorkspace workspace) async {
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
