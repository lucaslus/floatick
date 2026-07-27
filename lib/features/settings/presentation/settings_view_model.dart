import 'package:flutter/foundation.dart';

import '../../../core/storage/storage_failure.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SettingsRepository settingsRepository})
    : _repository = settingsRepository;

  final SettingsRepository _repository;

  AppSettings _settings = const AppSettings();
  StorageFailure? _error;
  bool _isLoading = false;
  bool _isSaving = false;

  AppSettings get settings => _settings;
  AppThemePreference get themePreference => _settings.themePreference;
  AppLanguagePreference get languagePreference => _settings.languagePreference;
  bool get alwaysOnTop => _settings.alwaysOnTop;
  StorageFailure? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String get storagePath => _repository.storagePath;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _repository.load();
    } on StorageFailure catch (error) {
      _settings = const AppSettings();
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    if (_isSaving || preference == _settings.themePreference) {
      return;
    }

    await _save(_settings.copyWith(themePreference: preference));
  }

  Future<void> setLanguagePreference(AppLanguagePreference preference) async {
    if (_isSaving || preference == _settings.languagePreference) {
      return;
    }

    await _save(_settings.copyWith(languagePreference: preference));
  }

  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (_isSaving || alwaysOnTop == _settings.alwaysOnTop) {
      return;
    }

    await _save(_settings.copyWith(alwaysOnTop: alwaysOnTop));
  }

  Future<void> _save(AppSettings nextSettings) async {
    final previousSettings = _settings;
    _settings = nextSettings;
    _error = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _repository.save(_settings);
    } on StorageFailure catch (error) {
      _settings = previousSettings;
      _error = error;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void dismissError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }
}
