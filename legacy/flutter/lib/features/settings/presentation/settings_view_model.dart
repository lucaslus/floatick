import 'package:flutter/foundation.dart';

import '../../../core/storage/storage_failure.dart';
import '../data/login_item_repository.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';
import '../domain/login_item_status.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required this.loginItemRepository,
  }) : _repository = settingsRepository;

  final SettingsRepository _repository;
  final LoginItemRepository loginItemRepository;

  AppSettings _settings = const AppSettings();
  LoginItemStatus _loginItemStatus = LoginItemStatus.disabled;
  StorageFailure? _error;
  LoginItemFailure? _loginItemError;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUpdatingLoginItem = false;

  AppSettings get settings => _settings;
  AppThemePreference get themePreference => _settings.themePreference;
  AppLanguagePreference get languagePreference => _settings.languagePreference;
  bool get alwaysOnTop => _settings.alwaysOnTop;
  bool get collapseWhenClickingOutside => _settings.collapseWhenClickingOutside;
  LoginItemStatus get loginItemStatus => _loginItemStatus;
  bool get openAtLogin => _loginItemStatus == LoginItemStatus.enabled;
  bool get canChangeOpenAtLogin =>
      !_isLoading &&
      !_isUpdatingLoginItem &&
      _loginItemStatus != LoginItemStatus.unsupported;
  StorageFailure? get error => _error;
  LoginItemFailure? get loginItemError => _loginItemError;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUpdatingLoginItem => _isUpdatingLoginItem;
  String get storagePath => _repository.storagePath;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _loginItemError = null;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      _loadStoredSettings(),
      _loadLoginItemStatus(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadStoredSettings() async {
    try {
      _settings = await _repository.load();
    } on StorageFailure catch (error) {
      _settings = const AppSettings();
      _error = error;
    }
  }

  Future<void> _loadLoginItemStatus() async {
    try {
      _loginItemStatus = await loginItemRepository.loadStatus();
      _loginItemError = _issueForStatus(_loginItemStatus);
    } on LoginItemFailure catch (error) {
      _loginItemStatus = LoginItemStatus.disabled;
      _loginItemError = error;
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

  Future<void> setCollapseWhenClickingOutside(bool enabled) async {
    if (_isSaving || enabled == _settings.collapseWhenClickingOutside) {
      return;
    }

    await _save(_settings.copyWith(collapseWhenClickingOutside: enabled));
  }

  Future<void> setOpenAtLogin(bool enabled) async {
    if (!canChangeOpenAtLogin || enabled == openAtLogin) {
      return;
    }

    final previousStatus = _loginItemStatus;
    _loginItemStatus = enabled
        ? LoginItemStatus.enabled
        : LoginItemStatus.disabled;
    _loginItemError = null;
    _isUpdatingLoginItem = true;
    notifyListeners();

    try {
      _loginItemStatus = await loginItemRepository.setEnabled(enabled);
      _loginItemError = _issueForStatus(_loginItemStatus);
    } on LoginItemFailure catch (error) {
      _loginItemStatus = previousStatus;
      _loginItemError = error;
    } finally {
      _isUpdatingLoginItem = false;
      notifyListeners();
    }
  }

  LoginItemFailure? _issueForStatus(LoginItemStatus status) {
    return switch (status) {
      LoginItemStatus.requiresApproval => const LoginItemFailure(
        kind: LoginItemFailureKind.requiresApproval,
      ),
      LoginItemStatus.unsupported => const LoginItemFailure(
        kind: LoginItemFailureKind.unsupported,
      ),
      LoginItemStatus.disabled || LoginItemStatus.enabled => null,
    };
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

  void dismissLoginItemError() {
    if (_loginItemError == null) {
      return;
    }
    _loginItemError = null;
    notifyListeners();
  }
}
