import 'dart:convert';
import 'dart:io';

import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/settings/data/settings_repository.dart';
import 'package:floatick/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late LocalSettingsRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'floatick-settings-repository-test-',
    );
    repository = LocalSettingsRepository(
      rootDirectory: Directory('${temporaryDirectory.path}/.floatick'),
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'missing storage creates the directory and uses system defaults',
    () async {
      final settings = await repository.load();

      expect(settings, const AppSettings());
      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.languagePreference, AppLanguagePreference.system);
      expect(settings.alwaysOnTop, isTrue);
      expect(await repository.rootDirectory.exists(), isTrue);
    },
  );

  test('save and load preserve the versioned settings schema', () async {
    const settings = AppSettings(
      themePreference: AppThemePreference.light,
      languagePreference: AppLanguagePreference.simplifiedChinese,
      alwaysOnTop: false,
    );

    await repository.save(settings);
    final loadedSettings = await repository.load();
    final json = jsonDecode(await File(repository.storagePath).readAsString());

    expect(loadedSettings, settings);
    expect(json, <String, Object?>{
      'version': 3,
      'theme': 'light',
      'language': 'zh',
      'alwaysOnTop': false,
    });
  });

  test('version 1 settings default to the system language', () async {
    await repository.rootDirectory.create(recursive: true);
    await File(
      repository.storagePath,
    ).writeAsString('{"version": 1, "theme": "dark"}');

    final settings = await repository.load();

    expect(settings.themePreference, AppThemePreference.dark);
    expect(settings.languagePreference, AppLanguagePreference.system);
    expect(settings.alwaysOnTop, isTrue);
  });

  test('version 2 settings default to keeping the window on top', () async {
    await repository.rootDirectory.create(recursive: true);
    await File(
      repository.storagePath,
    ).writeAsString('{"version": 2, "theme": "system", "language": "en"}');

    final settings = await repository.load();

    expect(settings.languagePreference, AppLanguagePreference.english);
    expect(settings.alwaysOnTop, isTrue);
  });

  test('damaged storage is reported and left unchanged', () async {
    await repository.rootDirectory.create(recursive: true);
    final file = File(repository.storagePath);
    const damagedContent = '{"version": 1, "theme": "sepia"}';
    await file.writeAsString(damagedContent);

    await expectLater(
      repository.load(),
      throwsA(
        isA<StorageFailure>().having(
          (error) => error.kind,
          'kind',
          StorageFailureKind.invalidData,
        ),
      ),
    );
    expect(await file.readAsString(), damagedContent);
  });

  test('unknown language is reported and left unchanged', () async {
    await repository.rootDirectory.create(recursive: true);
    final file = File(repository.storagePath);
    const damagedContent =
        '{"version": 2, "theme": "system", "language": "fr"}';
    await file.writeAsString(damagedContent);

    await expectLater(
      repository.load(),
      throwsA(
        isA<StorageFailure>().having(
          (error) => error.kind,
          'kind',
          StorageFailureKind.invalidData,
        ),
      ),
    );
    expect(await file.readAsString(), damagedContent);
  });

  test('invalid window level setting is reported and left unchanged', () async {
    await repository.rootDirectory.create(recursive: true);
    final file = File(repository.storagePath);
    const damagedContent =
        '{"version": 3, "theme": "system", "language": "en",'
        '"alwaysOnTop": "yes"}';
    await file.writeAsString(damagedContent);

    await expectLater(
      repository.load(),
      throwsA(
        isA<StorageFailure>().having(
          (error) => error.kind,
          'kind',
          StorageFailureKind.invalidData,
        ),
      ),
    );
    expect(await file.readAsString(), damagedContent);
  });
}
