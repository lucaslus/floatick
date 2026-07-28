import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @applicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Floatick'**
  String get applicationTitle;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open Floatick'**
  String get openApp;

  /// No description provided for @openAppHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reposition; click to open the todo list'**
  String get openAppHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageSystemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystemTooltip;

  /// No description provided for @languageSimplifiedChineseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageSimplifiedChineseTooltip;

  /// No description provided for @languageEnglishTooltip.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishTooltip;

  /// No description provided for @windowSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get windowSectionTitle;

  /// No description provided for @alwaysOnTopLabel.
  ///
  /// In en, this message translates to:
  /// **'Keep above other apps'**
  String get alwaysOnTopLabel;

  /// No description provided for @startupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get startupSectionTitle;

  /// No description provided for @openAtLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Open at login'**
  String get openAtLoginLabel;

  /// No description provided for @openAtLoginLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the login item setting.'**
  String get openAtLoginLoadError;

  /// No description provided for @openAtLoginUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the login item setting.'**
  String get openAtLoginUpdateError;

  /// No description provided for @openAtLoginApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow Floatick in System Settings → General → Login Items.'**
  String get openAtLoginApprovalRequired;

  /// No description provided for @openAtLoginUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Open at login requires macOS 13 or later.'**
  String get openAtLoginUnsupported;

  /// No description provided for @updatesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesSectionTitle;

  /// No description provided for @currentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String currentVersionLabel(String version);

  /// No description provided for @automaticUpdateChecksLabel.
  ///
  /// In en, this message translates to:
  /// **'Automatic checks'**
  String get automaticUpdateChecksLabel;

  /// No description provided for @checkForUpdatesButton.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkForUpdatesButton;

  /// No description provided for @checkingForUpdatesButton.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingForUpdatesButton;

  /// No description provided for @updateSettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Update settings are unavailable.'**
  String get updateSettingsLoadError;

  /// No description provided for @updateSettingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change update settings.'**
  String get updateSettingsSaveError;

  /// No description provided for @updateCheckError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates.'**
  String get updateCheckError;

  /// No description provided for @updateFeedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Update service isn\'t ready yet.'**
  String get updateFeedUnavailable;

  /// No description provided for @workingDirectorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Working directory'**
  String get workingDirectorySectionTitle;

  /// No description provided for @workingDirectorySemantics.
  ///
  /// In en, this message translates to:
  /// **'Working directory: {path}'**
  String workingDirectorySemantics(String path);

  /// No description provided for @closeSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close settings'**
  String get closeSettingsTooltip;

  /// No description provided for @themeSystemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystemTooltip;

  /// No description provided for @themeLightTooltip.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeLightTooltip;

  /// No description provided for @themeDarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeDarkTooltip;

  /// No description provided for @searchTodosHint.
  ///
  /// In en, this message translates to:
  /// **'Search todos'**
  String get searchTodosHint;

  /// No description provided for @searchArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Search archive'**
  String get searchArchiveHint;

  /// No description provided for @clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// No description provided for @filterByTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by tag'**
  String get filterByTagTitle;

  /// No description provided for @filterByTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter todos by tag'**
  String get filterByTagTooltip;

  /// No description provided for @closeTagFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close tag filter'**
  String get closeTagFilterTooltip;

  /// No description provided for @closeTagAssignmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close tag selection'**
  String get closeTagAssignmentTooltip;

  /// No description provided for @allTagsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'All todos'**
  String get allTagsFilterLabel;

  /// No description provided for @manageTagsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get manageTagsTooltip;

  /// No description provided for @manageTagsButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageTagsButtonLabel;

  /// No description provided for @assignTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get assignTagsTitle;

  /// No description provided for @assignTagsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Assign tags'**
  String get assignTagsTooltip;

  /// No description provided for @tagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @closeTagManagementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close tag management'**
  String get closeTagManagementTooltip;

  /// No description provided for @searchOrCreateTagHint.
  ///
  /// In en, this message translates to:
  /// **'Search or create a tag'**
  String get searchOrCreateTagHint;

  /// No description provided for @createTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get createTagTooltip;

  /// No description provided for @saveTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save tag'**
  String get saveTagTooltip;

  /// No description provided for @createTagModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Search · Return creates a tag'**
  String get createTagModeLabel;

  /// No description provided for @editTagModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Editing tag'**
  String get editTagModeLabel;

  /// No description provided for @tagNameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag name.'**
  String get tagNameRequiredMessage;

  /// No description provided for @tagNameTooLongMessage.
  ///
  /// In en, this message translates to:
  /// **'Use no more than {maxLength} characters.'**
  String tagNameTooLongMessage(int maxLength);

  /// No description provided for @duplicateTagNameMessage.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists.'**
  String get duplicateTagNameMessage;

  /// No description provided for @tagNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This tag no longer exists.'**
  String get tagNotFoundMessage;

  /// No description provided for @invalidTagColorMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid tag color.'**
  String get invalidTagColorMessage;

  /// No description provided for @tagStorageFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save tag changes.'**
  String get tagStorageFailureMessage;

  /// No description provided for @tagColorSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag color'**
  String get tagColorSemanticsLabel;

  /// No description provided for @tagUsageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String tagUsageCount(int count);

  /// No description provided for @editTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get editTagTooltip;

  /// No description provided for @deleteTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get deleteTagTooltip;

  /// No description provided for @cancelDeleteTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Keep tag'**
  String get cancelDeleteTagTooltip;

  /// No description provided for @confirmDeleteTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete tag and remove it from todos'**
  String get confirmDeleteTagTooltip;

  /// No description provided for @noMatchingTagsMessage.
  ///
  /// In en, this message translates to:
  /// **'No matching tags. Press Return to create this one.'**
  String get noMatchingTagsMessage;

  /// No description provided for @noTagsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Create one from the field above.'**
  String get noTagsYetMessage;

  /// No description provided for @noTagsToFilterMessage.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Open tag settings to create one.'**
  String get noTagsToFilterMessage;

  /// No description provided for @clearTagFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear tag filter'**
  String get clearTagFilterTooltip;

  /// No description provided for @allClearToday.
  ///
  /// In en, this message translates to:
  /// **'All clear for today'**
  String get allClearToday;

  /// No description provided for @activeTodoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task remaining} other{{count} tasks remaining}}'**
  String activeTodoCount(int count);

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @stickyBoardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticky Boards'**
  String get stickyBoardsTitle;

  /// No description provided for @stickyBoardsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open Sticky Boards'**
  String get stickyBoardsTooltip;

  /// No description provided for @closeStickyBoardsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close Sticky Boards'**
  String get closeStickyBoardsTooltip;

  /// No description provided for @backToStickyBoardsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to Sticky Boards'**
  String get backToStickyBoardsTooltip;

  /// No description provided for @searchOrCreateStickyBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Search or create a sticky board'**
  String get searchOrCreateStickyBoardHint;

  /// No description provided for @createStickyBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create sticky board'**
  String get createStickyBoardTooltip;

  /// No description provided for @stickyBoardNameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a sticky board name.'**
  String get stickyBoardNameRequiredMessage;

  /// No description provided for @stickyBoardNameTooLongMessage.
  ///
  /// In en, this message translates to:
  /// **'Use no more than {maxLength} characters.'**
  String stickyBoardNameTooLongMessage(int maxLength);

  /// No description provided for @duplicateStickyBoardNameMessage.
  ///
  /// In en, this message translates to:
  /// **'A sticky board with this name already exists.'**
  String get duplicateStickyBoardNameMessage;

  /// No description provided for @stickyBoardNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This sticky board no longer exists.'**
  String get stickyBoardNotFoundMessage;

  /// No description provided for @stickyBoardStorageFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save sticky board changes.'**
  String get stickyBoardStorageFailureMessage;

  /// No description provided for @stickyBoardTodoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 todo} other{{count} todos}}'**
  String stickyBoardTodoCount(int count);

  /// No description provided for @emptyStickyBoardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first sticky board'**
  String get emptyStickyBoardsTitle;

  /// No description provided for @emptyStickyBoardsMessage.
  ///
  /// In en, this message translates to:
  /// **'Group related todos without moving or duplicating them.'**
  String get emptyStickyBoardsMessage;

  /// No description provided for @noMatchingStickyBoardsMessage.
  ///
  /// In en, this message translates to:
  /// **'No matching sticky boards. Press Return to create this one.'**
  String get noMatchingStickyBoardsMessage;

  /// No description provided for @renameStickyBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename sticky board'**
  String get renameStickyBoardTooltip;

  /// No description provided for @deleteStickyBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete sticky board'**
  String get deleteStickyBoardTooltip;

  /// No description provided for @deleteStickyBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this sticky board?'**
  String get deleteStickyBoardTitle;

  /// No description provided for @deleteStickyBoardMessage.
  ///
  /// In en, this message translates to:
  /// **'Its todos will stay safely in All Todos.'**
  String get deleteStickyBoardMessage;

  /// No description provided for @keepStickyBoardAction.
  ///
  /// In en, this message translates to:
  /// **'Keep sticky board'**
  String get keepStickyBoardAction;

  /// No description provided for @pinStickyBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pin to desktop'**
  String get pinStickyBoardTooltip;

  /// No description provided for @unpinStickyBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unpin from desktop'**
  String get unpinStickyBoardTooltip;

  /// No description provided for @stickyBoardPinnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get stickyBoardPinnedLabel;

  /// No description provided for @addExistingTodoAction.
  ///
  /// In en, this message translates to:
  /// **'Add existing'**
  String get addExistingTodoAction;

  /// No description provided for @addExistingTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add existing todos'**
  String get addExistingTodoTitle;

  /// No description provided for @searchTodosToAddHint.
  ///
  /// In en, this message translates to:
  /// **'Search todos to add'**
  String get searchTodosToAddHint;

  /// No description provided for @noTodosAvailableForBoardMessage.
  ///
  /// In en, this message translates to:
  /// **'No todos are available to add.'**
  String get noTodosAvailableForBoardMessage;

  /// No description provided for @emptyPinnedStickyBoardMessage.
  ///
  /// In en, this message translates to:
  /// **'No todos on this board.'**
  String get emptyPinnedStickyBoardMessage;

  /// No description provided for @newTodoInStickyBoardAction.
  ///
  /// In en, this message translates to:
  /// **'New todo'**
  String get newTodoInStickyBoardAction;

  /// No description provided for @removeFromStickyBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from sticky board'**
  String get removeFromStickyBoardTooltip;

  /// No description provided for @stickyBoardDeleteKeepsTodosHint.
  ///
  /// In en, this message translates to:
  /// **'Deleting a sticky board never deletes its todos.'**
  String get stickyBoardDeleteKeepsTodosHint;

  /// No description provided for @collapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse (Esc)'**
  String get collapseTooltip;

  /// No description provided for @activeScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get activeScopeLabel;

  /// No description provided for @archiveScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveScopeLabel;

  /// No description provided for @newTodoDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'New todo'**
  String get newTodoDrawerTitle;

  /// No description provided for @todoDetailsDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get todoDetailsDrawerTitle;

  /// No description provided for @editTodoDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit todo'**
  String get editTodoDrawerTitle;

  /// No description provided for @editTodoAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTodoAction;

  /// No description provided for @closeTodoDrawerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close todo drawer'**
  String get closeTodoDrawerTooltip;

  /// No description provided for @todoTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get todoTitleLabel;

  /// No description provided for @todoTitleFieldHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get todoTitleFieldHint;

  /// No description provided for @todoContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get todoContentLabel;

  /// No description provided for @todoContentFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes with Markdown…'**
  String get todoContentFieldHint;

  /// No description provided for @markdownSupportedHint.
  ///
  /// In en, this message translates to:
  /// **'Markdown supported · ⌘ Return saves'**
  String get markdownSupportedHint;

  /// No description provided for @markdownWriteLabel.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get markdownWriteLabel;

  /// No description provided for @markdownPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get markdownPreviewLabel;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @createTodoAction.
  ///
  /// In en, this message translates to:
  /// **'Add todo'**
  String get createTodoAction;

  /// No description provided for @newTodoAction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newTodoAction;

  /// No description provided for @saveChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesAction;

  /// No description provided for @saveTodoFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this todo.'**
  String get saveTodoFailedMessage;

  /// No description provided for @todoNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This todo no longer exists.'**
  String get todoNotFoundMessage;

  /// No description provided for @noTodoContentTitle.
  ///
  /// In en, this message translates to:
  /// **'No details yet'**
  String get noTodoContentTitle;

  /// No description provided for @noTodoContentMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit this todo to add Markdown notes.'**
  String get noTodoContentMessage;

  /// No description provided for @markdownPreviewEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing to preview yet'**
  String get markdownPreviewEmptyMessage;

  /// No description provided for @markdownImageBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Images are not displayed in todo details.'**
  String get markdownImageBlockedMessage;

  /// No description provided for @viewTodoDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewTodoDetailsTooltip;

  /// No description provided for @dismissErrorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss error'**
  String get dismissErrorTooltip;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @incompleteStatus.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incompleteStatus;

  /// No description provided for @markIncompleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark incomplete'**
  String get markIncompleteTooltip;

  /// No description provided for @markCompleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markCompleteTooltip;

  /// No description provided for @todoTitleRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Todo title cannot be empty'**
  String get todoTitleRequiredHint;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @cancelEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get cancelEditTooltip;

  /// No description provided for @restoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restore to todos'**
  String get restoreTooltip;

  /// No description provided for @archiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveTooltip;

  /// No description provided for @deleteTodoPermanentlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteTodoPermanentlyTooltip;

  /// No description provided for @cancelDeleteTodoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Keep archived todo'**
  String get cancelDeleteTodoTooltip;

  /// No description provided for @confirmDeleteTodoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this todo'**
  String get confirmDeleteTodoTooltip;

  /// No description provided for @archivedTodoNoContentMessage.
  ///
  /// In en, this message translates to:
  /// **'No additional notes were saved.'**
  String get archivedTodoNoContentMessage;

  /// No description provided for @noSearchResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get noSearchResultsTitle;

  /// No description provided for @emptyArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get emptyArchiveTitle;

  /// No description provided for @emptyTodosTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do—enjoy the moment'**
  String get emptyTodosTitle;

  /// No description provided for @noSearchResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword'**
  String get noSearchResultsMessage;

  /// No description provided for @emptyArchiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Archived items will appear here'**
  String get emptyArchiveMessage;

  /// No description provided for @emptyTodosMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a new item above whenever you like'**
  String get emptyTodosMessage;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @storageInvalidDataError.
  ///
  /// In en, this message translates to:
  /// **'The local data file is damaged and was left unchanged.'**
  String get storageInvalidDataError;

  /// No description provided for @storageReadError.
  ///
  /// In en, this message translates to:
  /// **'Floatick couldn\'t read {path}.'**
  String storageReadError(String path);

  /// No description provided for @storageWriteError.
  ///
  /// In en, this message translates to:
  /// **'Floatick couldn\'t save to {path}.'**
  String storageWriteError(String path);

  /// No description provided for @storageHomeError.
  ///
  /// In en, this message translates to:
  /// **'Floatick couldn\'t resolve your macOS home directory.'**
  String get storageHomeError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
