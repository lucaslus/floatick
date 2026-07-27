// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get applicationTitle => 'Floatick';

  @override
  String get openApp => 'Open Floatick';

  @override
  String get openAppHint => 'Drag to reposition; click to open the todo list';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystemTooltip => 'Follow system';

  @override
  String get languageSimplifiedChineseTooltip => 'Simplified Chinese';

  @override
  String get languageEnglishTooltip => 'English';

  @override
  String get windowSectionTitle => 'Window';

  @override
  String get alwaysOnTopLabel => 'Keep above other apps';

  @override
  String get updatesSectionTitle => 'Updates';

  @override
  String currentVersionLabel(String version) {
    return 'v$version';
  }

  @override
  String get automaticUpdateChecksLabel => 'Automatic checks';

  @override
  String get checkForUpdatesButton => 'Check now';

  @override
  String get checkingForUpdatesButton => 'Checking…';

  @override
  String get updateSettingsLoadError => 'Update settings are unavailable.';

  @override
  String get updateSettingsSaveError => 'Couldn\'t change update settings.';

  @override
  String get updateCheckError => 'Couldn\'t check for updates.';

  @override
  String get updateFeedUnavailable => 'Update service isn\'t ready yet.';

  @override
  String get workingDirectorySectionTitle => 'Working directory';

  @override
  String workingDirectorySemantics(String path) {
    return 'Working directory: $path';
  }

  @override
  String get closeSettingsTooltip => 'Close settings';

  @override
  String get themeSystemTooltip => 'Follow system';

  @override
  String get themeLightTooltip => 'Light theme';

  @override
  String get themeDarkTooltip => 'Dark theme';

  @override
  String get searchTodosHint => 'Search todos';

  @override
  String get searchArchiveHint => 'Search archive';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get filterByTagTitle => 'Filter by tag';

  @override
  String get filterByTagTooltip => 'Filter todos by tag';

  @override
  String get closeTagFilterTooltip => 'Close tag filter';

  @override
  String get closeTagAssignmentTooltip => 'Close tag selection';

  @override
  String get allTagsFilterLabel => 'All todos';

  @override
  String get manageTagsTooltip => 'Manage tags';

  @override
  String get manageTagsButtonLabel => 'Manage';

  @override
  String get assignTagsTitle => 'Tags';

  @override
  String get assignTagsTooltip => 'Assign tags';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get closeTagManagementTooltip => 'Close tag management';

  @override
  String get searchOrCreateTagHint => 'Search or create a tag';

  @override
  String get createTagTooltip => 'Create tag';

  @override
  String get saveTagTooltip => 'Save tag';

  @override
  String get createTagModeLabel => 'Search · Return creates a tag';

  @override
  String get editTagModeLabel => 'Editing tag';

  @override
  String get tagNameRequiredMessage => 'Enter a tag name.';

  @override
  String tagNameTooLongMessage(int maxLength) {
    return 'Use no more than $maxLength characters.';
  }

  @override
  String get duplicateTagNameMessage => 'A tag with this name already exists.';

  @override
  String get tagNotFoundMessage => 'This tag no longer exists.';

  @override
  String get invalidTagColorMessage => 'Choose a valid tag color.';

  @override
  String get tagStorageFailureMessage => 'Couldn\'t save tag changes.';

  @override
  String get tagColorSemanticsLabel => 'Tag color';

  @override
  String tagUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get editTagTooltip => 'Edit tag';

  @override
  String get deleteTagTooltip => 'Delete tag';

  @override
  String get cancelDeleteTagTooltip => 'Keep tag';

  @override
  String get confirmDeleteTagTooltip => 'Delete tag and remove it from todos';

  @override
  String get noMatchingTagsMessage =>
      'No matching tags. Press Return to create this one.';

  @override
  String get noTagsYetMessage =>
      'No tags yet. Create one from the field above.';

  @override
  String get noTagsToFilterMessage =>
      'No tags yet. Open tag settings to create one.';

  @override
  String get clearTagFilterTooltip => 'Clear tag filter';

  @override
  String get allClearToday => 'All clear for today';

  @override
  String activeTodoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks remaining',
      one: '1 task remaining',
    );
    return '$_temp0';
  }

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get stickyBoardsTitle => 'Sticky Boards';

  @override
  String get stickyBoardsTooltip => 'Open Sticky Boards';

  @override
  String get closeStickyBoardsTooltip => 'Close Sticky Boards';

  @override
  String get backToStickyBoardsTooltip => 'Back to Sticky Boards';

  @override
  String get searchOrCreateStickyBoardHint => 'Search or create a sticky board';

  @override
  String get createStickyBoardTooltip => 'Create sticky board';

  @override
  String get stickyBoardNameRequiredMessage => 'Enter a sticky board name.';

  @override
  String stickyBoardNameTooLongMessage(int maxLength) {
    return 'Use no more than $maxLength characters.';
  }

  @override
  String get duplicateStickyBoardNameMessage =>
      'A sticky board with this name already exists.';

  @override
  String get stickyBoardNotFoundMessage =>
      'This sticky board no longer exists.';

  @override
  String get stickyBoardStorageFailureMessage =>
      'Couldn\'t save sticky board changes.';

  @override
  String stickyBoardTodoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count todos',
      one: '1 todo',
    );
    return '$_temp0';
  }

  @override
  String get emptyStickyBoardsTitle => 'Create your first sticky board';

  @override
  String get emptyStickyBoardsMessage =>
      'Group related todos without moving or duplicating them.';

  @override
  String get noMatchingStickyBoardsMessage =>
      'No matching sticky boards. Press Return to create this one.';

  @override
  String get renameStickyBoardTooltip => 'Rename sticky board';

  @override
  String get deleteStickyBoardTooltip => 'Delete sticky board';

  @override
  String get deleteStickyBoardTitle => 'Delete this sticky board?';

  @override
  String get deleteStickyBoardMessage =>
      'Its todos will stay safely in All Todos.';

  @override
  String get keepStickyBoardAction => 'Keep sticky board';

  @override
  String get confirmDeleteStickyBoardAction => 'Delete sticky board';

  @override
  String get pinStickyBoardTooltip => 'Pin to desktop';

  @override
  String get unpinStickyBoardTooltip => 'Unpin from desktop';

  @override
  String get stickyBoardPinnedLabel => 'Pinned';

  @override
  String get addExistingTodoAction => 'Add existing';

  @override
  String get addExistingTodoTitle => 'Add existing todos';

  @override
  String get searchTodosToAddHint => 'Search todos to add';

  @override
  String get noTodosAvailableForBoardMessage =>
      'No todos are available to add.';

  @override
  String get newTodoInStickyBoardAction => 'New todo';

  @override
  String get removeFromStickyBoardTooltip => 'Remove from sticky board';

  @override
  String get openMainListTooltip => 'Open main list';

  @override
  String get openMainListAction => 'Open in Floatick';

  @override
  String get stickyBoardDeleteKeepsTodosHint =>
      'Deleting a sticky board never deletes its todos.';

  @override
  String get collapseTooltip => 'Collapse (Esc)';

  @override
  String get activeScopeLabel => 'Todos';

  @override
  String get archiveScopeLabel => 'Archive';

  @override
  String get newTodoDrawerTitle => 'New todo';

  @override
  String get todoDetailsDrawerTitle => 'Details';

  @override
  String get editTodoDrawerTitle => 'Edit todo';

  @override
  String get editTodoAction => 'Edit';

  @override
  String get closeTodoDrawerTooltip => 'Close todo drawer';

  @override
  String get todoTitleLabel => 'Title';

  @override
  String get todoTitleFieldHint => 'What needs to be done?';

  @override
  String get todoContentLabel => 'Content';

  @override
  String get todoContentFieldHint => 'Add notes with Markdown…';

  @override
  String get markdownSupportedHint => 'Markdown supported · ⌘ Return saves';

  @override
  String get markdownWriteLabel => 'Write';

  @override
  String get markdownPreviewLabel => 'Preview';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get createTodoAction => 'Add todo';

  @override
  String get saveChangesAction => 'Save changes';

  @override
  String get saveTodoFailedMessage => 'Couldn\'t save this todo.';

  @override
  String get todoNotFoundMessage => 'This todo no longer exists.';

  @override
  String get noTodoContentTitle => 'No details yet';

  @override
  String get noTodoContentMessage => 'Edit this todo to add Markdown notes.';

  @override
  String get markdownPreviewEmptyMessage => 'Nothing to preview yet';

  @override
  String get markdownImageBlockedMessage =>
      'Images are not displayed in todo details.';

  @override
  String get viewTodoDetailsTooltip => 'View details';

  @override
  String get dismissErrorTooltip => 'Dismiss error';

  @override
  String get completedStatus => 'Completed';

  @override
  String get incompleteStatus => 'Incomplete';

  @override
  String get markIncompleteTooltip => 'Mark incomplete';

  @override
  String get markCompleteTooltip => 'Mark complete';

  @override
  String get todoTitleRequiredHint => 'Todo title cannot be empty';

  @override
  String get editTooltip => 'Edit';

  @override
  String get cancelEditTooltip => 'Cancel editing';

  @override
  String get restoreTooltip => 'Restore to todos';

  @override
  String get archiveTooltip => 'Archive';

  @override
  String get noSearchResultsTitle => 'No matching results';

  @override
  String get emptyArchiveTitle => 'Archive is empty';

  @override
  String get emptyTodosTitle => 'Nothing to do—enjoy the moment';

  @override
  String get noSearchResultsMessage => 'Try another keyword';

  @override
  String get emptyArchiveMessage => 'Archived items will appear here';

  @override
  String get emptyTodosMessage => 'Add a new item above whenever you like';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get storageInvalidDataError =>
      'The local data file is damaged and was left unchanged.';

  @override
  String storageReadError(String path) {
    return 'Floatick couldn\'t read $path.';
  }

  @override
  String storageWriteError(String path) {
    return 'Floatick couldn\'t save to $path.';
  }

  @override
  String get storageHomeError =>
      'Floatick couldn\'t resolve your macOS home directory.';
}
