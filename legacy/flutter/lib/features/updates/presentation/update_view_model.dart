import 'package:flutter/foundation.dart';

import '../data/update_repository.dart';

enum UpdateFailureKind { loadSettings, saveSettings, check, feedUnavailable }

class UpdateViewModel extends ChangeNotifier {
  UpdateViewModel({required UpdateRepository updateRepository})
    : _repository = updateRepository;

  final UpdateRepository _repository;

  bool _automaticallyChecksForUpdates = true;
  String _currentVersion = '—';
  UpdateFailureKind? _error;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isChecking = false;

  bool get automaticallyChecksForUpdates => _automaticallyChecksForUpdates;
  String get currentVersion => _currentVersion;
  UpdateFailureKind? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isChecking => _isChecking;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final settings = await _repository.loadSettings();
      _automaticallyChecksForUpdates = settings.automaticallyChecksForUpdates;
      _currentVersion = settings.currentVersion;
    } on Object catch (error, stackTrace) {
      _error = UpdateFailureKind.loadSettings;
      debugPrint('Floatick could not load update settings: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAutomaticallyChecksForUpdates(bool enabled) async {
    if (_isSaving || enabled == _automaticallyChecksForUpdates) {
      return;
    }

    final previousValue = _automaticallyChecksForUpdates;
    _automaticallyChecksForUpdates = enabled;
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.setAutomaticallyChecksForUpdates(enabled);
    } on Object catch (error, stackTrace) {
      _automaticallyChecksForUpdates = previousValue;
      _error = UpdateFailureKind.saveSettings;
      debugPrint('Floatick could not save update settings: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> checkForUpdates() async {
    if (_isChecking || _isLoading) {
      return;
    }

    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.checkForUpdates();
    } on UpdateFeedUnavailableException {
      _error = UpdateFailureKind.feedUnavailable;
    } on Object catch (error, stackTrace) {
      _error = UpdateFailureKind.check;
      debugPrint('Floatick could not check for updates: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isChecking = false;
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
