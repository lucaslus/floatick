enum AppThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemePreference(this.storageValue);

  final String storageValue;

  static AppThemePreference fromStorageValue(String value) {
    return values.firstWhere(
      (preference) => preference.storageValue == value,
      orElse: () {
        throw FormatException('Unknown theme preference: $value');
      },
    );
  }
}

enum AppLanguagePreference {
  system('system'),
  simplifiedChinese('zh'),
  english('en');

  const AppLanguagePreference(this.storageValue);

  final String storageValue;

  static AppLanguagePreference fromStorageValue(String value) {
    return values.firstWhere(
      (preference) => preference.storageValue == value,
      orElse: () {
        throw FormatException('Unknown language preference: $value');
      },
    );
  }
}

class AppSettings {
  const AppSettings({
    this.themePreference = AppThemePreference.system,
    this.languagePreference = AppLanguagePreference.system,
    this.alwaysOnTop = true,
    this.collapseWhenClickingOutside = true,
  });

  final AppThemePreference themePreference;
  final AppLanguagePreference languagePreference;
  final bool alwaysOnTop;
  final bool collapseWhenClickingOutside;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppLanguagePreference? languagePreference,
    bool? alwaysOnTop,
    bool? collapseWhenClickingOutside,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      collapseWhenClickingOutside:
          collapseWhenClickingOutside ?? this.collapseWhenClickingOutside,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawTheme = json['theme'];
    if (rawTheme != null && rawTheme is! String) {
      throw const FormatException('Settings theme must be a string.');
    }

    final rawLanguage = json['language'];
    if (rawLanguage != null && rawLanguage is! String) {
      throw const FormatException('Settings language must be a string.');
    }

    final rawAlwaysOnTop = json['alwaysOnTop'];
    if (rawAlwaysOnTop != null && rawAlwaysOnTop is! bool) {
      throw const FormatException('Settings alwaysOnTop must be a Boolean.');
    }

    final rawCollapseWhenClickingOutside = json['collapseWhenClickingOutside'];
    if (rawCollapseWhenClickingOutside != null &&
        rawCollapseWhenClickingOutside is! bool) {
      throw const FormatException(
        'Settings collapseWhenClickingOutside must be a Boolean.',
      );
    }

    return AppSettings(
      themePreference: rawTheme == null
          ? AppThemePreference.system
          : AppThemePreference.fromStorageValue(rawTheme),
      languagePreference: rawLanguage == null
          ? AppLanguagePreference.system
          : AppLanguagePreference.fromStorageValue(rawLanguage),
      alwaysOnTop: rawAlwaysOnTop ?? true,
      collapseWhenClickingOutside: rawCollapseWhenClickingOutside ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': 4,
      'theme': themePreference.storageValue,
      'language': languagePreference.storageValue,
      'alwaysOnTop': alwaysOnTop,
      'collapseWhenClickingOutside': collapseWhenClickingOutside,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        themePreference == other.themePreference &&
        languagePreference == other.languagePreference &&
        alwaysOnTop == other.alwaysOnTop &&
        collapseWhenClickingOutside == other.collapseWhenClickingOutside;
  }

  @override
  int get hashCode => Object.hash(
    themePreference,
    languagePreference,
    alwaysOnTop,
    collapseWhenClickingOutside,
  );
}
