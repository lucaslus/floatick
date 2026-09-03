import 'dart:async';

import 'package:floatick/features/updates/data/update_repository.dart';
import 'package:floatick/features/updates/domain/update_settings_snapshot.dart';
import 'package:floatick/features/updates/presentation/update_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryUpdateRepository repository;
  late UpdateViewModel controller;

  setUp(() {
    repository = _MemoryUpdateRepository();
    controller = UpdateViewModel(updateRepository: repository);
  });

  test('load exposes native Sparkle settings and app version', () async {
    repository.settings = const UpdateSettingsSnapshot(
      automaticallyChecksForUpdates: false,
      currentVersion: '0.2.0',
    );

    await controller.load();

    expect(controller.automaticallyChecksForUpdates, isFalse);
    expect(controller.currentVersion, '0.2.0');
    expect(controller.error, isNull);
  });

  test('automatic check preference changes immediately and persists', () async {
    await controller.load();
    final saveCompleter = Completer<void>();
    repository.pendingSave = saveCompleter;

    final operation = controller.setAutomaticallyChecksForUpdates(false);

    expect(controller.automaticallyChecksForUpdates, isFalse);
    expect(controller.isSaving, isTrue);

    saveCompleter.complete();
    await operation;

    expect(repository.settings.automaticallyChecksForUpdates, isFalse);
    expect(controller.isSaving, isFalse);
    expect(controller.error, isNull);
  });

  test('failed preference save rolls the visible value back', () async {
    await controller.load();
    repository.failNextSave = true;

    await controller.setAutomaticallyChecksForUpdates(false);

    expect(controller.automaticallyChecksForUpdates, isTrue);
    expect(controller.error, UpdateFailureKind.saveSettings);
    expect(controller.isSaving, isFalse);
  });

  test('manual check delegates to Sparkle once', () async {
    await controller.load();

    await controller.checkForUpdates();

    expect(repository.checkCount, 1);
    expect(controller.isChecking, isFalse);
    expect(controller.error, isNull);
  });

  test('unavailable first-release feed becomes a friendly status', () async {
    await controller.load();
    repository.feedUnavailable = true;

    await controller.checkForUpdates();

    expect(repository.checkCount, 1);
    expect(controller.isChecking, isFalse);
    expect(controller.error, UpdateFailureKind.feedUnavailable);
  });
}

class _MemoryUpdateRepository implements UpdateRepository {
  UpdateSettingsSnapshot settings = const UpdateSettingsSnapshot(
    automaticallyChecksForUpdates: true,
    currentVersion: '0.1.0',
  );
  Completer<void>? pendingSave;
  bool failNextSave = false;
  bool feedUnavailable = false;
  int checkCount = 0;

  @override
  Future<UpdateSettingsSnapshot> loadSettings() async => settings;

  @override
  Future<void> setAutomaticallyChecksForUpdates(bool enabled) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    final pendingSave = this.pendingSave;
    if (pendingSave != null) {
      await pendingSave.future;
      this.pendingSave = null;
    }
    settings = UpdateSettingsSnapshot(
      automaticallyChecksForUpdates: enabled,
      currentVersion: settings.currentVersion,
    );
  }

  @override
  Future<void> checkForUpdates() async {
    checkCount += 1;
    if (feedUnavailable) {
      throw const UpdateFeedUnavailableException();
    }
  }
}
