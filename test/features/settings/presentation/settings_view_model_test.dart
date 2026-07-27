import 'dart:async';

import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/settings/data/settings_repository.dart';
import 'package:floatick/features/settings/domain/app_settings.dart';
import 'package:floatick/features/settings/presentation/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemorySettingsRepository repository;
  late SettingsViewModel controller;

  setUp(() {
    repository = _MemorySettingsRepository();
    controller = SettingsViewModel(settingsRepository: repository);
  });

  test('load exposes persisted appearance preferences', () async {
    repository.savedSettings = const AppSettings(
      themePreference: AppThemePreference.dark,
      languagePreference: AppLanguagePreference.english,
      alwaysOnTop: false,
    );

    await controller.load();

    expect(controller.themePreference, AppThemePreference.dark);
    expect(controller.languagePreference, AppLanguagePreference.english);
    expect(controller.alwaysOnTop, isFalse);
    expect(controller.error, isNull);
  });

  test('theme changes immediately and persists the new preference', () async {
    await controller.load();
    final saveCompleter = Completer<void>();
    repository.pendingSave = saveCompleter;

    final operation = controller.setThemePreference(AppThemePreference.light);

    expect(controller.themePreference, AppThemePreference.light);
    expect(controller.isSaving, isTrue);

    saveCompleter.complete();
    await operation;

    expect(repository.savedSettings.themePreference, AppThemePreference.light);
    expect(controller.isSaving, isFalse);
    expect(controller.error, isNull);
  });

  test('a failed save rolls the visible preference back', () async {
    repository.savedSettings = const AppSettings(
      themePreference: AppThemePreference.dark,
    );
    await controller.load();
    repository.failNextSave = true;

    await controller.setThemePreference(AppThemePreference.light);

    expect(controller.themePreference, AppThemePreference.dark);
    expect(controller.error?.kind, StorageFailureKind.write);
    expect(controller.isSaving, isFalse);
  });

  test(
    'language changes immediately and persists the new preference',
    () async {
      await controller.load();
      final saveCompleter = Completer<void>();
      repository.pendingSave = saveCompleter;

      final operation = controller.setLanguagePreference(
        AppLanguagePreference.simplifiedChinese,
      );

      expect(
        controller.languagePreference,
        AppLanguagePreference.simplifiedChinese,
      );
      expect(controller.isSaving, isTrue);

      saveCompleter.complete();
      await operation;

      expect(
        repository.savedSettings.languagePreference,
        AppLanguagePreference.simplifiedChinese,
      );
      expect(controller.isSaving, isFalse);
      expect(controller.error, isNull);
    },
  );

  test('a failed language save rolls the visible preference back', () async {
    repository.savedSettings = const AppSettings(
      languagePreference: AppLanguagePreference.english,
    );
    await controller.load();
    repository.failNextSave = true;

    await controller.setLanguagePreference(
      AppLanguagePreference.simplifiedChinese,
    );

    expect(controller.languagePreference, AppLanguagePreference.english);
    expect(controller.error?.kind, StorageFailureKind.write);
    expect(controller.isSaving, isFalse);
  });

  test('window level changes immediately and persists', () async {
    await controller.load();

    await controller.setAlwaysOnTop(false);

    expect(controller.alwaysOnTop, isFalse);
    expect(repository.savedSettings.alwaysOnTop, isFalse);
    expect(controller.error, isNull);
  });

  test(
    'a failed window level save rolls the visible preference back',
    () async {
      await controller.load();
      repository.failNextSave = true;

      await controller.setAlwaysOnTop(false);

      expect(controller.alwaysOnTop, isTrue);
      expect(controller.error?.kind, StorageFailureKind.write);
    },
  );
}

class _MemorySettingsRepository implements SettingsRepository {
  AppSettings savedSettings = const AppSettings();
  Completer<void>? pendingSave;
  bool failNextSave = false;

  @override
  String get storagePath => '/tmp/floatick-settings-test/settings.json';

  @override
  Future<AppSettings> load() async => savedSettings;

  @override
  Future<void> save(AppSettings settings) async {
    if (failNextSave) {
      failNextSave = false;
      throw const StorageFailure(kind: StorageFailureKind.write);
    }
    final pendingSave = this.pendingSave;
    if (pendingSave != null) {
      await pendingSave.future;
      this.pendingSave = null;
    }
    savedSettings = settings;
  }
}
