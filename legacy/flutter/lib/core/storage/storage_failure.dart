enum StorageFailureKind { invalidData, read, write, homeDirectoryUnavailable }

final class StorageFailure implements Exception {
  const StorageFailure({required this.kind, this.path, this.cause});

  final StorageFailureKind kind;
  final String? path;
  final Object? cause;

  @override
  String toString() => 'StorageFailure(kind: $kind, path: $path)';
}
