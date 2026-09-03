import '../core/storage/storage_failure.dart';
import 'app_localizations.dart';

extension StorageFailureLocalizations on AppLocalizations {
  String messageForStorageFailure(StorageFailure failure) {
    return switch (failure.kind) {
      StorageFailureKind.invalidData => storageInvalidDataError,
      StorageFailureKind.read => storageReadError(failure.path ?? '.floatick'),
      StorageFailureKind.write => storageWriteError(
        failure.path ?? '.floatick',
      ),
      StorageFailureKind.homeDirectoryUnavailable => storageHomeError,
    };
  }
}
