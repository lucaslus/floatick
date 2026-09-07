// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get applicationTitle => 'Floatick';

  @override
  String get openApp => '打开 Floatick';

  @override
  String get openAppHint => '拖动可移动位置，点击展开待办列表';

  @override
  String get settingsTitle => '设置';

  @override
  String get appearanceSectionTitle => '外观';

  @override
  String get languageSectionTitle => '语言';

  @override
  String get languageSystemTooltip => '跟随系统';

  @override
  String get languageSimplifiedChineseTooltip => '简体中文';

  @override
  String get languageEnglishTooltip => 'English';

  @override
  String get windowSectionTitle => '窗口';

  @override
  String get alwaysOnTopLabel => '始终置顶';

  @override
  String get collapseWhenClickingOutsideLabel => '点击外部时收起';

  @override
  String get startupSectionTitle => '启动';

  @override
  String get openAtLoginLabel => '登录时打开';

  @override
  String get openAtLoginLoadError => '暂时无法读取登录项设置。';

  @override
  String get openAtLoginUpdateError => '无法修改登录项设置。';

  @override
  String get openAtLoginApprovalRequired => '请前往“系统设置 → 通用 → 登录项”允许 Floatick。';

  @override
  String get openAtLoginUnsupported => '登录时打开需要 macOS 13 或更高版本。';

  @override
  String get updatesSectionTitle => '更新';

  @override
  String currentVersionLabel(String version) {
    return 'v$version';
  }

  @override
  String get automaticUpdateChecksLabel => '自动检查';

  @override
  String get checkForUpdatesButton => '立即检查';

  @override
  String get checkingForUpdatesButton => '检查中…';

  @override
  String get updateSettingsLoadError => '暂时无法读取更新设置。';

  @override
  String get updateSettingsSaveError => '无法修改更新设置。';

  @override
  String get updateCheckError => '暂时无法检查更新。';

  @override
  String get updateFeedUnavailable => '更新服务暂未就绪。';

  @override
  String get workingDirectorySectionTitle => '工作目录';

  @override
  String workingDirectorySemantics(String path) {
    return '工作目录：$path';
  }

  @override
  String get closeSettingsTooltip => '关闭设置';

  @override
  String get themeSystemTooltip => '跟随系统';

  @override
  String get themeLightTooltip => '浅色主题';

  @override
  String get themeDarkTooltip => '深色主题';

  @override
  String get searchTodosHint => '搜索待办';

  @override
  String get searchArchiveHint => '搜索归档';

  @override
  String get clearSearchTooltip => '清除搜索';

  @override
  String get filterByTagTitle => '按标签筛选';

  @override
  String get filterByTagTooltip => '按标签筛选待办';

  @override
  String get closeTagFilterTooltip => '关闭标签筛选';

  @override
  String get closeTagAssignmentTooltip => '关闭标签选择';

  @override
  String get allTagsFilterLabel => '全部待办';

  @override
  String get manageTagsTooltip => '管理标签';

  @override
  String get manageTagsButtonLabel => '管理';

  @override
  String get assignTagsTitle => '标签';

  @override
  String get assignTagsTooltip => '添加标签';

  @override
  String get tagsTitle => '标签';

  @override
  String get closeTagManagementTooltip => '关闭标签管理';

  @override
  String get searchOrCreateTagHint => '搜索或创建标签';

  @override
  String get createTagTooltip => '创建标签';

  @override
  String get saveTagTooltip => '保存标签';

  @override
  String get createTagModeLabel => '搜索 · 按 Return 创建';

  @override
  String get editTagModeLabel => '正在编辑标签';

  @override
  String get tagNameRequiredMessage => '请输入标签名称。';

  @override
  String tagNameTooLongMessage(int maxLength) {
    return '标签最多 $maxLength 个字符。';
  }

  @override
  String get duplicateTagNameMessage => '已经存在同名标签。';

  @override
  String get tagNotFoundMessage => '这个标签已不存在。';

  @override
  String get invalidTagColorMessage => '请选择有效的标签颜色。';

  @override
  String get tagStorageFailureMessage => '无法保存标签修改。';

  @override
  String get tagColorSemanticsLabel => '标签颜色';

  @override
  String tagUsageCount(int count) {
    return '$count 项';
  }

  @override
  String get editTagTooltip => '编辑标签';

  @override
  String get deleteTagTooltip => '删除标签';

  @override
  String get cancelDeleteTagTooltip => '保留标签';

  @override
  String get confirmDeleteTagTooltip => '删除标签并从待办中移除';

  @override
  String get noMatchingTagsMessage => '没有匹配标签，按 Return 可直接创建。';

  @override
  String get noTagsYetMessage => '还没有标签，可以在上方创建。';

  @override
  String get noTagsToFilterMessage => '还没有标签，可从标签设置中创建。';

  @override
  String get clearTagFilterTooltip => '清除标签筛选';

  @override
  String get allClearToday => '今天已经清空';

  @override
  String activeTodoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项待完成',
    );
    return '$_temp0';
  }

  @override
  String get settingsTooltip => '设置';

  @override
  String get collapseTooltip => '收起（Esc）';

  @override
  String get activeScopeLabel => '待办';

  @override
  String get archiveScopeLabel => '归档';

  @override
  String get newTodoDrawerTitle => '新建待办';

  @override
  String get todoDetailsDrawerTitle => '详情';

  @override
  String get editTodoDrawerTitle => '编辑待办';

  @override
  String get editTodoAction => '编辑';

  @override
  String get closeTodoDrawerTooltip => '关闭待办抽屉';

  @override
  String get todoTitleLabel => '标题';

  @override
  String get todoTitleFieldHint => '标题';

  @override
  String get todoContentLabel => '内容';

  @override
  String get todoContentFieldHint => '使用 Markdown 添加更多说明…';

  @override
  String get markdownWriteLabel => '编辑';

  @override
  String get markdownPreviewLabel => '预览';

  @override
  String get cancelAction => '取消';

  @override
  String get confirmAction => '确认';

  @override
  String get createTodoAction => '添加待办';

  @override
  String get newTodoAction => '新建';

  @override
  String get saveChangesAction => '保存修改';

  @override
  String get saveTodoFailedMessage => '无法保存这个待办。';

  @override
  String get todoNotFoundMessage => '这个待办已不存在。';

  @override
  String get noTodoContentTitle => '还没有详细内容';

  @override
  String get noTodoContentMessage => '编辑待办即可添加 Markdown 说明。';

  @override
  String get markdownPreviewEmptyMessage => '暂无可预览内容';

  @override
  String get markdownImageBlockedMessage => '预览中暂不显示图片。';

  @override
  String get viewTodoDetailsTooltip => '查看详情';

  @override
  String get copyTodoAsMarkdownTooltip => '复制为 Markdown';

  @override
  String get todoCopiedAsMarkdownMessage => '已复制为 Markdown';

  @override
  String get todoCopyFailedMessage => '无法复制这个待办。';

  @override
  String get moreTodoActionsTooltip => '更多操作';

  @override
  String get todoActionsSheetTitle => '操作';

  @override
  String get dismissErrorTooltip => '关闭错误提示';

  @override
  String get completedStatus => '已完成';

  @override
  String get incompleteStatus => '未完成';

  @override
  String get doingStatus => '进行中';

  @override
  String get filterDoingTooltip => '只看进行中的待办';

  @override
  String get clearDoingFilterTooltip => '显示全部待办';

  @override
  String get emptyDoingTodosTitle => '暂无进行中的待办';

  @override
  String get emptyDoingTodosMessage => '开始一项待办，进入专注状态';

  @override
  String get startDoingTooltip => '开始进行';

  @override
  String get stopDoingTooltip => '退回待办';

  @override
  String get markIncompleteTooltip => '标记为未完成';

  @override
  String get markCompleteTooltip => '标记为已完成';

  @override
  String get editTooltip => '编辑';

  @override
  String get cancelEditTooltip => '取消编辑';

  @override
  String get restoreTooltip => '恢复到待办';

  @override
  String get archiveTooltip => '归档';

  @override
  String get deleteTodoPermanentlyTooltip => '永久删除';

  @override
  String get deleteTodoConfirmationTitle => '删除这个待办？';

  @override
  String get deleteTodoConfirmationMessage => '此操作无法撤销。';

  @override
  String get deleteTodoAction => '删除';

  @override
  String get cancelDeleteTodoTooltip => '保留归档待办';

  @override
  String get confirmDeleteTodoTooltip => '永久删除这个待办';

  @override
  String get archivedTodoNoContentMessage => '没有保存更多说明。';

  @override
  String get noSearchResultsTitle => '没有匹配的结果';

  @override
  String get emptyArchiveTitle => '归档还是空的';

  @override
  String get emptyTodosTitle => '没有待办，享受此刻';

  @override
  String get noSearchResultsMessage => '换一个关键词试试';

  @override
  String get emptyArchiveMessage => '归档的事项会保存在这里';

  @override
  String get emptyTodosMessage => '在上方随时添加新事项';

  @override
  String get todoTabLabel => '待办';

  @override
  String get notesTabLabel => '笔记';

  @override
  String noteCountLabel(int count) {
    return '$count 条笔记';
  }

  @override
  String get searchNotesHint => '搜索笔记';

  @override
  String get searchNoteArchiveHint => '搜索笔记归档';

  @override
  String get newNoteAction => '新建';

  @override
  String get newNoteDrawerTitle => '新建笔记';

  @override
  String get editNoteDrawerTitle => '编辑笔记';

  @override
  String get closeNoteDrawerTooltip => '关闭笔记抽屉';

  @override
  String get noteTitleHint => '标题';

  @override
  String get noteTitleLabel => '标题';

  @override
  String get noteContentLabel => '内容';

  @override
  String get noteContentHint => '先记下来，稍后再整理…';

  @override
  String get noteAutoSaving => '正在自动保存…';

  @override
  String get noteAutoSaved => '已自动保存';

  @override
  String get noteAutoSaveFailed => '自动保存失败，请重试';

  @override
  String get noteEmptyDraftHint => '空白笔记不会保存';

  @override
  String get finishNoteAction => '完成';

  @override
  String get pinnedNotesLabel => '置顶';

  @override
  String get noteWithoutContent => '暂无正文';

  @override
  String get pinNoteTooltip => '置顶笔记';

  @override
  String get unpinNoteTooltip => '取消置顶';

  @override
  String get archiveNoteTooltip => '归档笔记';

  @override
  String get restoreNoteTooltip => '恢复笔记';

  @override
  String get deleteNoteTooltip => '永久删除笔记';

  @override
  String get emptyNotesTitle => '写下第一条笔记';

  @override
  String get emptyNotesMessage => '灵感、日报和小技巧，都可以随手记在这里';

  @override
  String get emptyNoteArchiveTitle => '笔记归档还是空的';

  @override
  String get emptyNoteArchiveMessage => '归档的笔记会保存在这里';

  @override
  String get todayLabel => '今天';

  @override
  String get yesterdayLabel => '昨天';

  @override
  String get storageInvalidDataError => '本地数据文件已损坏，文件保持不变。';

  @override
  String storageReadError(String path) {
    return 'Floatick 无法读取 $path。';
  }

  @override
  String storageWriteError(String path) {
    return 'Floatick 无法保存到 $path。';
  }

  @override
  String get storageHomeError => 'Floatick 无法获取当前 macOS 用户目录。';
}
