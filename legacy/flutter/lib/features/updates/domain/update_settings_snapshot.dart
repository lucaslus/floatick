class UpdateSettingsSnapshot {
  const UpdateSettingsSnapshot({
    required this.automaticallyChecksForUpdates,
    required this.currentVersion,
  });

  final bool automaticallyChecksForUpdates;
  final String currentVersion;

  factory UpdateSettingsSnapshot.fromPlatformValue(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Update settings must be returned as a map.');
    }

    final automaticallyChecks = value['automaticallyChecksForUpdates'];
    final currentVersion = value['currentVersion'];
    if (automaticallyChecks is! bool ||
        currentVersion is! String ||
        currentVersion.trim().isEmpty) {
      throw const FormatException(
        'Update settings contain invalid platform values.',
      );
    }

    return UpdateSettingsSnapshot(
      automaticallyChecksForUpdates: automaticallyChecks,
      currentVersion: currentVersion,
    );
  }
}
