import 'dart:async';

import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/settings/data/login_item_repository.dart';
import 'package:floatick/features/settings/data/settings_repository.dart';
import 'package:floatick/features/settings/domain/app_settings.dart';
import 'package:floatick/features/settings/domain/login_item_status.dart';
import 'package:floatick/features/settings/presentation/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemorySettingsRepository repository;
  late _MemoryLoginItemRepository loginItemRepository;
  late SettingsViewModel controller;

  setUp(() {
    repository = _MemorySettingsRepository();
    loginItemRepository = _MemoryLoginItemRepository();
    controller = SettingsViewModel(
      settingsRepository: repository,
      loginItemRepository: loginItemRepository,
    );
  });

  test('load exposes persisted appearance preferences', () async {
    repository.savedSettings = const AppSettings(
      themePreference: AppThemePreference.dark,
      languagePreference: AppLanguagePreference.english,
      alwaysOnTop: false,
    );
    loginItemRepository.status = LoginItemStatus.enabled;

    await controller.load();

    expect(controller.themePreference, AppThemePreference.dark);
    expect(controller.languagePreference, AppLanguagePreference.english);
    expect(controller.alwaysOnTop, isFalse);
    expect(controller.openAtLogin, isTrue);
    expect(controller.error, isNull);
    expect(controller.loginItemError, isNull);
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

  test(
    'login item changes immediately and synchronizes native state',
    () async {
      await controller.load();
      final updateCompleter = Completer<void>();
      loginItemRepository.pendingUpdate = updateCompleter;

      final operation = controller.setOpenAtLogin(true);

      expect(controller.openAtLogin, isTrue);
      expect(controller.isUpdatingLoginItem, isTrue);

      updateCompleter.complete();
      await operation;

      expect(loginItemRepository.setEnabledValues, <bool>[true]);
      expect(loginItemRepository.status, LoginItemStatus.enabled);
      expect(controller.openAtLogin, isTrue);
      expect(controller.isUpdatingLoginItem, isFalse);
      expect(controller.loginItemError, isNull);
    },
  );

  test('a failed login item update rolls the visible state back', () async {
    await controller.load();
    loginItemRepository.failNextUpdate = true;

    await controller.setOpenAtLogin(true);

    expect(controller.openAtLogin, isFalse);
    expect(controller.loginItemError?.kind, LoginItemFailureKind.update);
    expect(controller.isUpdatingLoginItem, isFalse);
  });

  test('login item approval requirements are exposed to the UI', () async {
    await controller.load();
    loginItemRepository.nextStatus = LoginItemStatus.requiresApproval;

    await controller.setOpenAtLogin(true);

    expect(controller.openAtLogin, isFalse);
    expect(
      controller.loginItemError?.kind,
      LoginItemFailureKind.requiresApproval,
    );
  });
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

class _MemoryLoginItemRepository implements LoginItemRepository {
  LoginItemStatus status = LoginItemStatus.disabled;
  LoginItemStatus? nextStatus;
  Completer<void>? pendingUpdate;
  bool failNextUpdate = false;
  final List<bool> setEnabledValues = <bool>[];

  @override
  Future<LoginItemStatus> loadStatus() async => status;

  @override
  Future<LoginItemStatus> setEnabled(bool enabled) async {
    setEnabledValues.add(enabled);
    final pendingUpdate = this.pendingUpdate;
    if (pendingUpdate != null) {
      await pendingUpdate.future;
      this.pendingUpdate = null;
    }
    if (failNextUpdate) {
      failNextUpdate = false;
      throw const LoginItemFailure(kind: LoginItemFailureKind.update);
    }
    status =
        nextStatus ??
        (enabled ? LoginItemStatus.enabled : LoginItemStatus.disabled);
    nextStatus = null;
    return status;
  }
}
