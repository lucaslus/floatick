import 'dart:convert';
import 'dart:io';

import '../../../core/storage/storage_failure.dart';
import '../domain/app_settings.dart';

abstract interface class SettingsRepository {
  String get storagePath;

  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository({Directory? rootDirectory})
    : rootDirectory = rootDirectory ?? _defaultRootDirectory();

  static const directoryName = '.floatick';
  static const fileName = 'settings.json';

  final Directory rootDirectory;

  File get _storageFile => File('${rootDirectory.path}/$fileName');

  @override
  String get storagePath => _storageFile.path;

  @override
  Future<AppSettings> load() async {
    try {
      await rootDirectory.create(recursive: true);
      if (!await _storageFile.exists()) {
        return const AppSettings();
      }

      final decoded = jsonDecode(await _storageFile.readAsString());
      if (decoded is! Map<dynamic, dynamic>) {
        throw const FormatException(
          'Settings storage root must be a JSON object.',
        );
      }
      return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
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
  Future<void> save(AppSettings settings) async {
    final temporaryFile = File(
      '${_storageFile.path}.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      await rootDirectory.create(recursive: true);
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(settings.toJson());
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
