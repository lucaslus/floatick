import 'package:floatick/features/updates/domain/update_settings_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete platform settings snapshot', () {
    final snapshot = UpdateSettingsSnapshot.fromPlatformValue(
      <Object?, Object?>{
        'automaticallyChecksForUpdates': true,
        'currentVersion': '0.1.0',
      },
    );

    expect(snapshot.automaticallyChecksForUpdates, isTrue);
    expect(snapshot.currentVersion, '0.1.0');
  });

  test('rejects incomplete or incorrectly typed platform values', () {
    expect(
      () => UpdateSettingsSnapshot.fromPlatformValue(<Object?, Object?>{
        'automaticallyChecksForUpdates': 'yes',
        'currentVersion': '0.1.0',
      }),
      throwsFormatException,
    );
    expect(
      () => UpdateSettingsSnapshot.fromPlatformValue(null),
      throwsFormatException,
    );
  });
}
