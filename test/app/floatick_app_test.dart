import 'dart:async';

import 'package:floatick/app/floatick_app.dart';
import 'package:floatick/core/platform/window_bridge.dart';
import 'package:floatick/core/storage/storage_failure.dart';
import 'package:floatick/features/notes/data/note_repository.dart';
import 'package:floatick/features/notes/domain/note_item.dart';
import 'package:floatick/features/notes/presentation/note_view_model.dart';
import 'package:floatick/features/settings/data/login_item_repository.dart';
import 'package:floatick/features/settings/data/settings_repository.dart';
import 'package:floatick/features/settings/domain/app_settings.dart';
import 'package:floatick/features/settings/domain/login_item_status.dart';
import 'package:floatick/features/settings/presentation/settings_view_model.dart';
import 'package:floatick/features/sticky_boards/data/sticky_board_repository.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board_workspace.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_view_model.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_window_coordinator.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/features/todos/presentation/todo_editor_drawer.dart';
import 'package:floatick/features/todos/presentation/todo_panel.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:floatick/features/updates/data/update_repository.dart';
import 'package:floatick/features/updates/domain/update_settings_snapshot.dart';
import 'package:floatick/features/updates/presentation/update_view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('floating icon expands into an editable todo list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _WidgetTestRepository();
    final controller = TodoViewModel(
      todoRepository: repository,
      tagRepository: _WidgetTestTagRepository(),
      clock: () => DateTime.utc(2026, 7, 23, 8),
      idGenerator: () => 'new-todo',
    );
    final noteRepository = _WidgetTestNoteRepository();
    final noteController = NoteViewModel(
      repository: noteRepository,
      clock: () => DateTime.utc(2026, 7, 23, 8),
      idGenerator: () => 'new-note',
    );
    final windowBridge = _WidgetTestWindowBridge();
    final settingsRepository = _WidgetTestSettingsRepository();
    final loginItemRepository = _WidgetTestLoginItemRepository();
    final settingsController = SettingsViewModel(
      settingsRepository: settingsRepository,
      loginItemRepository: loginItemRepository,
    );
    final updateRepository = _WidgetTestUpdateRepository();
    final updateController = UpdateViewModel(
      updateRepository: updateRepository,
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
    );
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: controller,
      windowBridge: windowBridge,
    );
    await controller.load();
    await noteController.load();
    await settingsController.load();
    await updateController.load();
    await stickyBoardController.load();

    await tester.pumpWidget(
      FloatickApp(
        controller: controller,
        noteController: noteController,
        settingsController: settingsController,
        updateController: updateController,
        stickyBoardController: stickyBoardController,
        stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
        windowBridge: windowBridge,
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();
    expect(windowBridge.floatingIconCounts, <int>[0]);
    expect(windowBridge.preferredThemeValues, <String>['system']);
    final tooltipMouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await tooltipMouse.addPointer(
      location: tester.getCenter(find.byKey(const Key('collapse-button'))),
    );

    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();
    expect(windowBridge.expandedValues, <bool>[true]);
    expect(windowBridge.expandedAnimatedValues, <bool>[true]);
    expect(
      tester
          .widget<TooltipVisibility>(
            find.byKey(const Key('panel-tooltip-visibility')),
          )
          .visible,
      isFalse,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('收起（Esc）'), findsNothing);

    await tooltipMouse.moveTo(Offset.zero);
    await tester.pump();
    expect(
      tester
          .widget<TooltipVisibility>(
            find.byKey(const Key('panel-tooltip-visibility')),
          )
          .visible,
      isTrue,
    );
    await tooltipMouse.moveTo(
      tester.getCenter(find.byKey(const Key('collapse-button'))),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('收起（Esc）'), findsOneWidget);
    await tooltipMouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    await tooltipMouse.removePointer();

    expect(windowBridge.expandedValues, <bool>[true]);
    expect(find.text('Floatick'), findsNothing);
    expect(find.text('今天已经清空'), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-brand-mark')), findsOneWidget);
    expect(find.byKey(const Key('search-field')), findsOneWidget);
    expect(find.byKey(const Key('tag-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('add-todo-button')), findsOneWidget);
    expect(find.byKey(const Key('archive-scope-button')), findsOneWidget);
    expect(find.text('待办  0'), findsNothing);
    expect(find.text('归档  0'), findsNothing);

    await tester.tap(find.byKey(const Key('archive-scope-button')));
    await tester.pumpAndSettle();
    expect(find.text('归档 · 0'), findsOneWidget);
    expect(find.text('搜索归档'), findsOneWidget);
    expect(find.byKey(const Key('add-todo-button')), findsNothing);

    await tester.tap(find.byKey(const Key('archive-scope-button')));
    await tester.pumpAndSettle();
    expect(find.text('今天已经清空'), findsOneWidget);
    expect(find.text('搜索待办'), findsOneWidget);
    expect(find.byKey(const Key('add-todo-button')), findsOneWidget);

    final searchRect = tester.getRect(find.byKey(const Key('search-field')));
    final tagFilterRect = tester.getRect(
      find.byKey(const Key('tag-filter-button')),
    );
    final newTodoRect = tester.getRect(
      find.byKey(const Key('add-todo-button')),
    );
    expect(tagFilterRect.left, greaterThan(searchRect.right));
    expect(newTodoRect.left, greaterThan(tagFilterRect.right));
    expect((tagFilterRect.center.dy - searchRect.center.dy).abs(), lessThan(1));
    expect((newTodoRect.center.dy - searchRect.center.dy).abs(), lessThan(1));
    expect(tagFilterRect.size, const Size.square(42));
    expect(newTodoRect.height, 42);
    expect(find.text('新建'), findsOneWidget);
    final panelSurface = tester.widget<DecoratedBox>(
      find.byKey(const Key('todo-panel-surface')),
    );
    final panelDecoration = panelSurface.decoration as BoxDecoration;
    expect(panelDecoration.boxShadow, isNull);
    expect(find.byKey(const Key('settings-drawer-slide')), findsNothing);
    expect(find.byKey(const Key('tag-drawer-slide')), findsNothing);
    expect(find.byKey(const Key('sticky-board-drawer-slide')), findsNothing);
    expect(find.byKey(const Key('todo-drawer-slide')), findsNothing);
    expect(find.byKey(const Key('todo-context-scrim')), findsNothing);

    expect(find.byKey(const Key('todo-tab')), findsOneWidget);
    expect(find.byKey(const Key('note-tab')), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-tab')));
    await tester.pumpAndSettle();
    expect(find.text('搜索笔记'), findsOneWidget);
    expect(find.byKey(const Key('tag-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('add-note-button')), findsOneWidget);
    expect(find.text('写下第一条笔记'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-note-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-editor-drawer')), findsOneWidget);
    expect(find.byKey(const Key('note-document-editor')), findsOneWidget);
    expect(find.byKey(const Key('note-template-daily')), findsNothing);
    expect(find.byKey(const Key('note-editor-tag-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-editor-tag-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-assignment-drawer')), findsOneWidget);
    expect(find.byKey(const Key('note-editor-drawer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tag-assignment-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-document-editor')), findsOneWidget);
    await tester.tap(find.byKey(const Key('close-note-editor')));
    await tester.pumpAndSettle();
    expect(noteRepository.savedItems, isEmpty);

    await tester.tap(find.byKey(const Key('todo-tab')));
    await tester.pumpAndSettle();
    expect(find.text('搜索待办'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-drawer')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('窗口'), findsOneWidget);
    expect(find.text('始终置顶'), findsOneWidget);
    expect(find.text('点击外部时收起'), findsOneWidget);
    expect(find.text('启动'), findsOneWidget);
    expect(find.text('登录时打开'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
    expect(find.text('工作目录'), findsOneWidget);
    expect(find.text('/tmp/floatick-widget-test'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open_rounded), findsNothing);
    expect(find.text('选择 Floatick 使用的界面主题'), findsNothing);
    expect(find.text('设置仅保存在这台 Mac 上'), findsNothing);
    expect(find.text('自动'), findsNothing);
    expect(find.text('浅色'), findsNothing);
    expect(find.text('深色'), findsNothing);
    expect(find.byKey(const Key('theme-system')), findsOneWidget);
    expect(find.byKey(const Key('theme-light')), findsOneWidget);
    expect(find.byKey(const Key('theme-dark')), findsOneWidget);
    expect(find.byKey(const Key('language-system')), findsOneWidget);
    expect(find.byKey(const Key('language-zh')), findsOneWidget);
    expect(find.byKey(const Key('language-en')), findsOneWidget);
    expect(find.byKey(const Key('automatic-update-checks')), findsOneWidget);
    expect(find.byKey(const Key('check-for-updates')), findsOneWidget);
    expect(find.text('每天检查一次，安装前会询问你'), findsNothing);
    expect(find.text('自动检查'), findsOneWidget);
    expect(find.text('立即检查'), findsOneWidget);
    final collapseWhenClickingOutsideText = tester.widget<Text>(
      find.text('点击外部时收起'),
    );
    expect(collapseWhenClickingOutsideText.maxLines, 2);
    expect(collapseWhenClickingOutsideText.overflow, TextOverflow.ellipsis);
    expect(collapseWhenClickingOutsideText.style?.fontSize, 11);
    final automaticUpdateChecksText = tester.widget<Text>(find.text('自动检查'));
    expect(automaticUpdateChecksText.maxLines, 2);
    expect(automaticUpdateChecksText.overflow, TextOverflow.ellipsis);
    expect(automaticUpdateChecksText.style?.fontSize, 11);
    expect(find.byType(Switch), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('automatic-update-toggle'))),
      const Size(32, 18),
    );
    expect(
      tester.getSize(find.byKey(const Key('always-on-top-toggle'))),
      const Size(32, 18),
    );
    expect(
      tester.getSize(
        find.byKey(const Key('collapse-when-clicking-outside-toggle')),
      ),
      const Size(32, 18),
    );
    expect(
      tester.getSize(find.byKey(const Key('open-at-login-toggle'))),
      const Size(32, 18),
    );
    expect(settingsController.openAtLogin, isFalse);
    await tester.tap(find.byKey(const Key('open-at-login-setting')));
    await tester.pumpAndSettle();
    expect(settingsController.openAtLogin, isTrue);
    expect(loginItemRepository.setEnabledValues, <bool>[true]);
    expect(windowBridge.alwaysOnTopValues, <bool>[true]);
    await tester.tap(find.byKey(const Key('always-on-top-setting')));
    await tester.pumpAndSettle();
    expect(settingsController.alwaysOnTop, isFalse);
    expect(settingsRepository.savedSettings.alwaysOnTop, isFalse);
    expect(windowBridge.alwaysOnTopValues, <bool>[true, false]);
    expect(settingsController.collapseWhenClickingOutside, isTrue);
    await tester.tap(
      find.byKey(const Key('collapse-when-clicking-outside-setting')),
    );
    await tester.pumpAndSettle();
    expect(settingsController.collapseWhenClickingOutside, isFalse);
    expect(
      settingsRepository.savedSettings.collapseWhenClickingOutside,
      isFalse,
    );
    expect(
      tester.getSize(find.byKey(const Key('update-settings-section'))).height,
      lessThan(105),
    );
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('settings-drawer-slide')))
          .offset,
      Offset.zero,
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('settings-drawer-pointer')),
          )
          .ignoring,
      isFalse,
    );
    final systemThemeButton = tester.widget<IconButton>(
      find.byKey(const Key('theme-system')),
    );
    expect(systemThemeButton.isSelected, isTrue);
    expect(
      systemThemeButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      Colors.transparent,
    );

    await tester.tap(find.byKey(const Key('automatic-update-checks')));
    await tester.pumpAndSettle();
    expect(updateController.automaticallyChecksForUpdates, isFalse);
    expect(updateRepository.automaticallyChecksForUpdates, isFalse);

    await tester.tap(find.byKey(const Key('check-for-updates')));
    await tester.pumpAndSettle();
    expect(updateRepository.checkCount, 1);

    updateRepository.feedUnavailable = true;
    await tester.tap(find.byKey(const Key('check-for-updates')));
    await tester.pumpAndSettle();
    expect(find.text('更新服务暂未就绪。'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pumpAndSettle();

    expect(settingsController.themePreference, AppThemePreference.dark);
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('settings-drawer'))),
      ).brightness,
      Brightness.dark,
    );
    expect(
      settingsRepository.savedSettings.themePreference,
      AppThemePreference.dark,
    );

    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pumpAndSettle();

    expect(settingsController.themePreference, AppThemePreference.light);
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('settings-drawer'))),
      ).brightness,
      Brightness.light,
    );
    expect(
      settingsRepository.savedSettings.themePreference,
      AppThemePreference.light,
    );
    expect(windowBridge.preferredThemeValues, <String>[
      'system',
      'dark',
      'light',
    ]);

    await tester.tap(find.byKey(const Key('settings-close')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('settings-drawer-slide')))
          .offset,
      const Offset(1, 0),
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('settings-drawer-pointer')),
          )
          .ignoring,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(windowBridge.expandedValues, <bool>[true]);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('settings-drawer-slide')))
          .offset,
      const Offset(1, 0),
    );

    await tester.tap(find.byKey(const Key('add-todo-button')));
    await tester.pumpAndSettle();
    expect(find.text('新建待办'), findsOneWidget);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
          .offset,
      Offset.zero,
    );
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Design the floating icon',
    );
    await tester.enterText(
      find.byKey(const Key('todo-content-field')),
      '## Goal\n\nPolish the **Dock** experience.',
    );
    await tester.tap(find.byKey(const Key('markdown-preview-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('todo-content-preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(find.text('Design the floating icon').hitTestable(), findsOneWidget);
    expect(find.text('1 项待完成'), findsOneWidget);
    expect(repository.savedItems.single.title, 'Design the floating icon');
    expect(
      repository.savedItems.single.content,
      '## Goal\n\nPolish the **Dock** experience.',
    );
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
          .offset,
      const Offset(0, 1),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(
      tester.getCenter(find.text('Design the floating icon').hitTestable()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more-todo-new-todo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('todo-action-view-new-todo')));
    await tester.pumpAndSettle();
    expect(find.text('详情'), findsOneWidget);
    expect(find.byKey(const Key('todo-details-title')), findsOneWidget);
    expect(find.byKey(const Key('todo-details-markdown')), findsOneWidget);
    expect(
      tester
          .widget<Markdown>(
            find.descendant(
              of: find.byKey(const Key('todo-details-markdown')),
              matching: find.byType(Markdown),
            ),
          )
          .data,
      '## Goal\n\nPolish the **Dock** experience.',
    );
    await tester.tap(find.byKey(const Key('todo-details-edit')));
    await tester.pumpAndSettle();
    expect(find.text('编辑待办'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Polish the Floatick icon',
    );
    await tester.enterText(
      find.byKey(const Key('todo-content-field')),
      '- Match macOS sizing\n- Keep transparent corners',
    );
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();
    expect(find.text('详情'), findsOneWidget);
    expect(repository.savedItems.single.title, 'Polish the Floatick icon');
    expect(
      repository.savedItems.single.content,
      '- Match macOS sizing\n- Keep transparent corners',
    );
    await tester.tap(find.byKey(const Key('todo-drawer-close')));
    await tester.pumpAndSettle();

    await mouse.moveTo(
      tester.getCenter(find.text('Polish the Floatick icon').hitTestable()),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 50));
    await mouse.moveTo(
      tester.getCenter(find.text('Polish the Floatick icon').hitTestable()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final moreButton = find.byKey(const Key('more-todo-new-todo'));
    expect(moreButton, findsOneWidget);
    await tester.tap(moreButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('todo-action-edit-new-todo')));
    await tester.pumpAndSettle();
    expect(find.text('编辑待办'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Cancelled edit',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Polish the Floatick icon').hitTestable(), findsOneWidget);
    expect(windowBridge.expandedValues, <bool>[true]);

    windowBridge.collapseRequestHandler?.call();
    await tester.pumpAndSettle();
    expect(windowBridge.expandedValues, <bool>[true]);

    await settingsController.setCollapseWhenClickingOutside(true);
    windowBridge.collapseRequestHandler?.call();
    await tester.pumpAndSettle();

    expect(windowBridge.expandedValues, <bool>[true, false]);
    expect(windowBridge.expandedAnimatedValues, <bool>[true, true]);
    expect(
      tester
          .widget<TooltipVisibility>(
            find.byKey(const Key('panel-tooltip-visibility')),
          )
          .visible,
      isFalse,
    );

    final expansionBarrier = Completer<void>();
    windowBridge.setExpandedBarrier = expansionBarrier.future;
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pump();
    await tester.pump();
    expect(windowBridge.expandedValues.last, isTrue);

    windowBridge.collapseRequestHandler?.call();
    expansionBarrier.complete();
    await tester.pumpAndSettle();

    expect(windowBridge.expandedValues, <bool>[true, false, true, false]);
  });

  testWidgets('tags can be created, assigned, and used as a filter', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var todoSequence = 0;
    var tagSequence = 0;
    final tagRepository = _WidgetTestTagRepository();
    final controller = TodoViewModel(
      todoRepository: _WidgetTestRepository(),
      tagRepository: tagRepository,
      idGenerator: () => 'todo-${++todoSequence}',
      tagIdGenerator: () => switch (++tagSequence) {
        1 => 'tag-work',
        2 => 'tag-personal',
        _ => 'tag-$tagSequence',
      },
    );
    final settingsController = SettingsViewModel(
      settingsRepository: _WidgetTestSettingsRepository(),
      loginItemRepository: _WidgetTestLoginItemRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
    );
    final windowBridge = _WidgetTestWindowBridge();
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: controller,
      windowBridge: windowBridge,
    );
    await controller.load();
    await settingsController.load();
    await updateController.load();
    await stickyBoardController.load();

    await tester.pumpWidget(
      FloatickApp(
        controller: controller,
        settingsController: settingsController,
        updateController: updateController,
        stickyBoardController: stickyBoardController,
        stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
        windowBridge: windowBridge,
        locale: const Locale('en'),
      ),
    );
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tag-filter-button')));
    await tester.pumpAndSettle();
    expect(find.text('Filter by tag'), findsOneWidget);
    expect(find.byKey(const Key('tag-filter-drawer')), findsOneWidget);
    expect(find.byKey(const Key('manage-tags-button')), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('tag-drawer-slide')))
          .offset,
      Offset.zero,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('tag-filter-drawer'))).dx,
      tester.getTopLeft(find.byKey(const Key('todo-panel-surface'))).dx,
    );

    await tester.tap(find.byKey(const Key('manage-tags-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-filter-drawer')), findsNothing);
    expect(find.byKey(const Key('tag-management-drawer')), findsOneWidget);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('tag-drawer-slide')))
          .offset,
      Offset.zero,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('tag-management-drawer'))).dx,
      tester.getTopLeft(find.byKey(const Key('todo-panel-surface'))).dx,
    );

    await tester.enterText(
      find.byKey(const Key('tag-search-create-field')),
      'Work',
    );
    expect(
      tester.widget<IconButton>(find.byKey(const Key('submit-tag'))).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('submit-tag')));
    await tester.pumpAndSettle();
    expect(controller.tags.single.name, 'Work');
    expect(tagRepository.savedWorkspace.tags.single.name, 'Work');
    expect(find.byKey(const Key('managed-tag-tag-work')), findsOneWidget);
    expect(
      tester
          .widget<ListView>(find.byKey(const Key('tag-management-list')))
          .itemExtent,
      44,
    );

    await tester.tap(find.byKey(const Key('tag-management-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-todo-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
          .offset,
      Offset.zero,
    );
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Tagged task',
    );
    expect(find.byKey(const Key('todo-editor-tag-button')), findsOneWidget);
    expect(find.byKey(const Key('todo-editor-tag-tag-work')), findsNothing);
    await tester.tap(find.byKey(const Key('todo-editor-tag-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-assignment-drawer')), findsOneWidget);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
          .offset,
      Offset.zero,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(find.byKey(const Key('todo-context-scrim')))
          .opacity,
      1,
    );
    expect(
      find.byKey(const Key('todo-title-field')).hitTestable(),
      findsNothing,
    );
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('tag-drawer-slide')))
          .offset,
      Offset.zero,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('tag-assignment-drawer'))).dx,
      tester.getTopLeft(find.byKey(const Key('todo-panel-surface'))).dx,
    );
    await tester.tap(find.byKey(const Key('tag-assignment-tag-work')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('todo-editor-tag-tag-work')), findsOneWidget);

    await tester.tap(find.byKey(const Key('manage-tags-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-management-drawer')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('tag-search-create-field')),
      'Personal',
    );
    await tester.tap(find.byKey(const Key('submit-tag')));
    await tester.pumpAndSettle();
    expect(controller.tags.map((tag) => tag.name), <String>[
      'Work',
      'Personal',
    ]);
    expect(tagRepository.savedWorkspace.tags.map((tag) => tag.name), <String>[
      'Work',
      'Personal',
    ]);
    await tester.tap(find.byKey(const Key('tag-management-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-assignment-drawer')), findsOneWidget);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
          .offset,
      Offset.zero,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('todo-title-field')))
          .controller
          ?.text,
      'Tagged task',
    );

    await tester.tap(find.byKey(const Key('tag-assignment-tag-personal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-assignment-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-assignment-drawer')), findsNothing);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
          .offset,
      Offset.zero,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(find.byKey(const Key('todo-context-scrim')))
          .opacity,
      0,
    );
    expect(
      find.byKey(const Key('todo-editor-tag-tag-personal')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('save-todo-details')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();
    expect(controller.items.single.id, 'todo-1');
    expect(controller.tagIdsForTodo('todo-1'), <String>[
      'tag-work',
      'tag-personal',
    ]);
    expect(find.text('Tagged task').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const Key('assign-tags-todo-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-todo-1-tag-work')));
    await tester.pumpAndSettle();
    expect(controller.tagIdsForTodo('todo-1'), <String>['tag-personal']);
    await tester.tap(find.byKey(const Key('assign-todo-1-tag-work')));
    await tester.pumpAndSettle();
    expect(controller.tagIdsForTodo('todo-1'), <String>[
      'tag-work',
      'tag-personal',
    ]);
    expect(
      tester.getSize(find.byKey(const Key('todo-tag-todo-1-tag-work'))).height,
      17,
    );
    await tester.tap(
      find.byKey(const Key('tag-assignment-bottom-sheet-close')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-assignment-bottom-sheet')), findsNothing);

    await tester.tap(find.byKey(const Key('add-todo-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Other task',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(
      await controller.create(
        'Personal task',
        tagIds: const <String>['tag-personal'],
      ),
      isNotNull,
    );
    expect(
      await controller.createTag(name: 'Unused', colorValue: 0xFF20B8A8),
      TagMutationResult.success,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tag-filter-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListView>(find.byKey(const Key('tag-filter-list')))
          .itemExtent,
      44,
    );
    await tester.tap(find.byKey(const Key('tag-filter-tag-work')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('tag-filter-tag-work')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('tag-filter-tag-work')),
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('tag-filter-drawer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tag-filter-tag-personal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-filter-drawer')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('tag-filter-count')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('tag-filter-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-tag-filter')), findsNothing);
    expect(find.byKey(const Key('tag-filter-count')), findsOneWidget);
    expect(find.text('Tagged task').hitTestable(), findsOneWidget);
    expect(find.text('Personal task').hitTestable(), findsOneWidget);
    expect(find.text('Other task').hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('collapse-button')));
    await tester.pumpAndSettle();
    expect(windowBridge.expandedValues.last, isFalse);
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topLeft);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-filter-button')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopRight(find.byKey(const Key('tag-filter-drawer'))).dx,
      tester.getTopRight(find.byKey(const Key('todo-panel-surface'))).dx,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('tag-filter-count')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('tag-filter-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-filter-count')), findsNothing);
    await tester.tap(find.byKey(const Key('tag-filter-tag-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-filter-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clear-active-tag-filters')), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear-active-tag-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tag-filter-count')), findsNothing);
    expect(find.text('Tagged task').hitTestable(), findsOneWidget);
    expect(find.text('Personal task').hitTestable(), findsOneWidget);
    expect(find.text('Other task').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const Key('tag-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage-tags-button')));
    await tester.pumpAndSettle();

    expect(
      tester.getTopRight(find.byKey(const Key('tag-management-drawer'))).dx,
      tester.getTopRight(find.byKey(const Key('todo-panel-surface'))).dx,
    );
  });

  testWidgets('sticky boards create virtual groups and reuse the todo editor', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final todoRepository = _WidgetTestRepository()
      ..savedItems = <TodoItem>[
        TodoItem(
          id: 'existing-todo',
          title: 'Review the launch checklist',
          createdAt: DateTime.utc(2026, 7, 26, 9),
        ),
        TodoItem(
          id: 'content-only-todo',
          title: 'Plan the next iteration',
          content: 'Private launch phrase',
          createdAt: DateTime.utc(2026, 7, 26, 8),
        ),
      ];
    final tagRepository = _WidgetTestTagRepository()
      ..savedWorkspace = TagWorkspace(
        tags: <TodoTag>[
          TodoTag(
            id: 'tag-focus',
            name: 'Focus',
            colorValue: 0xFF4C8FF5,
            createdAt: DateTime.utc(2026, 7, 26, 7),
          ),
        ],
        assignments: const <String, List<String>>{
          'existing-todo': <String>['tag-focus'],
        },
      );
    var todoSequence = 0;
    final todoController = TodoViewModel(
      todoRepository: todoRepository,
      tagRepository: tagRepository,
      idGenerator: () => 'created-todo-${++todoSequence}',
    );
    final stickyBoardRepository = _WidgetTestStickyBoardRepository();
    final stickyBoardController = StickyBoardViewModel(
      repository: stickyBoardRepository,
      idGenerator: () => 'board-launch',
    );
    final settingsController = SettingsViewModel(
      settingsRepository: _WidgetTestSettingsRepository(),
      loginItemRepository: _WidgetTestLoginItemRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final windowBridge = _WidgetTestWindowBridge();
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: todoController,
      windowBridge: windowBridge,
      windowLauncher: (_) async {},
    );
    await Future.wait<void>(<Future<void>>[
      todoController.load(),
      stickyBoardController.load(),
      settingsController.load(),
      updateController.load(),
    ]);

    await tester.pumpWidget(
      FloatickApp(
        controller: todoController,
        settingsController: settingsController,
        updateController: updateController,
        stickyBoardController: stickyBoardController,
        stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
        windowBridge: windowBridge,
        locale: const Locale('en'),
      ),
    );
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sticky-boards-button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('sticky-boards-button')),
        matching: find.byIcon(Icons.sticky_note_2_outlined),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('sticky-boards-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('sticky-board-management-drawer')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('sticky-board-search-create-field')),
      'Launch',
    );
    await tester.tap(find.byKey(const Key('submit-sticky-board')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('sticky-board-thumbnail-grid')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sticky-board-board-launch')), findsOneWidget);
    expect(
      find.byKey(const Key('sticky-board-thumbnail-board-launch')),
      findsOneWidget,
    );
    final pinButton = find.byKey(
      const Key('toggle-sticky-board-pin-board-launch'),
    );
    expect(pinButton, findsOneWidget);
    await tester.tap(pinButton);
    await tester.pumpAndSettle();
    expect(stickyBoardController.boardById('board-launch')?.isPinned, isTrue);
    expect(
      find.descendant(
        of: pinButton,
        matching: find.byIcon(Icons.push_pin_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(pinButton);
    await tester.pumpAndSettle();
    expect(stickyBoardController.boardById('board-launch')?.isPinned, isFalse);

    final boardMouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(boardMouse.removePointer);
    await boardMouse.addPointer();
    await boardMouse.moveTo(
      tester.getCenter(
        find.byKey(const Key('sticky-board-thumbnail-board-launch')),
      ),
    );
    await tester.pumpAndSettle();
    final boardRectBeforeConfirmation = tester.getRect(
      find.byKey(const Key('sticky-board-thumbnail-board-launch')),
    );
    await tester.tap(find.byKey(const Key('delete-sticky-board-board-launch')));
    await tester.pumpAndSettle();

    final deleteConfirmation = find.byKey(
      const Key('sticky-board-delete-confirmation-board-launch'),
    );
    final cancelDeleteBoard = find.byKey(
      const Key('cancel-delete-sticky-board-board-launch'),
    );
    final confirmDeleteBoard = find.byKey(
      const Key('confirm-delete-sticky-board-board-launch'),
    );
    expect(deleteConfirmation, findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(cancelDeleteBoard, findsOneWidget);
    expect(confirmDeleteBoard, findsOneWidget);
    expect(
      find.descendant(of: confirmDeleteBoard, matching: find.text('Confirm')),
      findsOneWidget,
    );
    expect(find.text('Delete sticky board'), findsNothing);
    expect(
      tester.getRect(
        find.byKey(const Key('sticky-board-thumbnail-board-launch')),
      ),
      boardRectBeforeConfirmation,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(cancelDeleteBoard);
    await tester.pumpAndSettle();
    expect(deleteConfirmation, findsNothing);
    expect(stickyBoardController.boardById('board-launch'), isNotNull);
    await boardMouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sticky-board-board-launch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sticky-board-detail-drawer')), findsOneWidget);

    tester.widget<TodoPanel>(find.byType(TodoPanel)).onCollapse();
    await tester.pumpAndSettle();
    expect(windowBridge.expandedValues, <bool>[true, false]);
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();
    expect(windowBridge.expandedValues, <bool>[true, false, true]);
    expect(find.byKey(const Key('sticky-board-detail-drawer')), findsOneWidget);
    expect(
      tester
          .widget<AnimatedSlide>(
            find.byKey(const Key('sticky-board-drawer-slide')),
          )
          .offset,
      Offset.zero,
    );

    await tester.tap(find.byKey(const Key('sticky-board-add-existing')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('sticky-board-todo-picker-drawer')),
      findsOneWidget,
    );
    final pickerTile = tester.widget<CheckboxListTile>(
      find.byKey(const Key('sticky-board-picker-existing-todo')),
    );
    final pickerShape = pickerTile.shape as RoundedRectangleBorder;
    expect(
      pickerShape.borderRadius,
      const BorderRadius.all(Radius.circular(11)),
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('sticky-board-picker-existing-todo')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Material &&
              widget.clipBehavior == Clip.antiAlias &&
              widget.shape == pickerShape,
        ),
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('sticky-board-todo-search')),
      'Private launch phrase',
    );
    await tester.pump();
    expect(
      find.byKey(const Key('sticky-board-picker-content-only-todo')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const Key('sticky-board-todo-search')),
      'Focus',
    );
    await tester.pump();
    expect(
      find.byKey(const Key('sticky-board-picker-existing-todo')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('sticky-board-picker-existing-todo')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Sticky Boards'));
    await tester.pumpAndSettle();
    expect(stickyBoardController.todoIdsForBoard('board-launch'), <String>[
      'existing-todo',
    ]);
    expect(
      find.byKey(const Key('sticky-board-todo-existing-todo')),
      findsOneWidget,
    );
    final stickyBoardDetail = find.byKey(
      const Key('sticky-board-detail-drawer'),
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(
          const Key('sticky-board-managed-tag-existing-todo-tag-focus'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(
          const Key('sticky-board-managed-time-existing-todo'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(const Key('toggle-todo-existing-todo')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(const Key('edit-todo-existing-todo')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(const Key('view-todo-existing-todo')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(const Key('archive-todo-existing-todo')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(const Key('assign-tags-existing-todo')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(const Key('remove-from-board-existing-todo')),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(
          const Key('sticky-board-managed-open-details-existing-todo'),
        ),
      ),
    );
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(
      find.descendant(
        of: stickyBoardDetail,
        matching: find.byKey(
          const Key('sticky-board-managed-open-details-existing-todo'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sticky-board-todo-details')), findsOneWidget);
    expect(find.byKey(const Key('sticky-board-details-edit')), findsNothing);
    await tester.tap(find.byKey(const Key('sticky-board-details-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sticky-board-new-todo')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Share the release notes',
    );
    stickyBoardRepository.failNextSave = true;
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('save-todo-details')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(
      todoController.items.where(
        (item) => item.title == 'Share the release notes',
      ),
      hasLength(1),
    );
    expect(stickyBoardController.todoCountForBoard('board-launch'), 1);
    expect(find.byKey(const Key('todo-title-field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(
      todoController.items.map((item) => item.id),
      contains('created-todo-1'),
    );
    expect(stickyBoardController.todoCountForBoard('board-launch'), 2);
    expect(stickyBoardController.todoIdsForBoard('board-launch'), <String>[
      'existing-todo',
      'created-todo-1',
    ]);
    expect(find.text('Share the release notes'), findsWidgets);

    stickyBoardWindowCoordinator.requestMainWindow(
      const StickyBoardMainWindowRequest(
        boardId: 'board-launch',
        destination: StickyBoardMainWindowDestination.todoEdit,
        todoId: 'existing-todo',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit todo'), findsOneWidget);
    expect(
      tester.widget<TodoEditorDrawer>(find.byType(TodoEditorDrawer)).item?.id,
      'existing-todo',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('todo-title-field')))
          .controller
          ?.text,
      'Review the launch checklist',
    );
    await tester.tap(find.byKey(const Key('todo-drawer-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close Sticky Boards'));
    await tester.pumpAndSettle();

    tester.widget<TodoPanel>(find.byType(TodoPanel)).onCollapse();
    await tester.pumpAndSettle();
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedSlide>(
            find.byKey(const Key('sticky-board-drawer-slide')),
          )
          .offset,
      isNot(Offset.zero),
    );
    expect(find.byKey(const Key('search-field')).hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(const Key('sticky-boards-button')));
    await tester.pumpAndSettle();
    await boardMouse.moveTo(
      tester.getCenter(
        find.byKey(const Key('sticky-board-thumbnail-board-launch')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-sticky-board-board-launch')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm-delete-sticky-board-board-launch')),
    );
    await tester.pumpAndSettle();

    expect(stickyBoardController.boardById('board-launch'), isNull);
    expect(todoController.itemById('existing-todo'), isNotNull);
    expect(todoController.itemById('created-todo-1'), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permanent deletion waits for sticky board cleanup', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final archivedTodo = TodoItem(
      id: 'archived-linked',
      title: 'Archived linked todo',
      createdAt: DateTime.utc(2026, 7, 26, 8),
      archivedAt: DateTime.utc(2026, 7, 26, 9),
    );
    final todoRepository = _WidgetTestRepository()
      ..savedItems = <TodoItem>[archivedTodo];
    final boardRepository = _WidgetTestStickyBoardRepository()
      ..savedWorkspace = StickyBoardWorkspace(
        boards: <StickyBoard>[
          StickyBoard(
            id: 'board-linked',
            name: 'Linked',
            colorValue: 0xFF20B8A8,
            createdAt: DateTime.utc(2026, 7, 26, 7),
          ),
        ],
        boardTodoIds: const <String, List<String>>{
          'board-linked': <String>['archived-linked'],
        },
      );
    final todoController = TodoViewModel(
      todoRepository: todoRepository,
      tagRepository: _WidgetTestTagRepository(),
    );
    final boardController = StickyBoardViewModel(repository: boardRepository);
    final settingsController = SettingsViewModel(
      settingsRepository: _WidgetTestSettingsRepository(),
      loginItemRepository: _WidgetTestLoginItemRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final windowBridge = _WidgetTestWindowBridge();
    final coordinator = StickyBoardWindowCoordinator(
      boardController: boardController,
      todoController: todoController,
      windowBridge: windowBridge,
    );
    await Future.wait<void>(<Future<void>>[
      todoController.load(),
      boardController.load(),
      settingsController.load(),
      updateController.load(),
    ]);

    await tester.pumpWidget(
      FloatickApp(
        controller: todoController,
        settingsController: settingsController,
        updateController: updateController,
        stickyBoardController: boardController,
        stickyBoardWindowCoordinator: coordinator,
        windowBridge: windowBridge,
        locale: const Locale('en'),
      ),
    );
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('archive-scope-button')));
    await tester.pumpAndSettle();
    expect(find.text('Archive · 1'), findsOneWidget);
    expect(find.text('Archive  1'), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('Archived linked todo')));
    await tester.pumpAndSettle();

    boardRepository.failNextSave = true;
    await tester.tap(find.byKey(const Key('more-todo-archived-linked')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('todo-action-delete-archived-linked')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm-delete-todo-archived-linked')),
    );
    await tester.pumpAndSettle();

    expect(todoController.itemById('archived-linked'), archivedTodo);
    expect(todoRepository.savedItems, <TodoItem>[archivedTodo]);
    expect(boardController.todoIdsForBoard('board-linked'), <String>[
      'archived-linked',
    ]);
    expect(find.text("Floatick couldn't save to .floatick."), findsOneWidget);
  });

  testWidgets('English locale translates the primary todo experience', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TodoViewModel(
      todoRepository: _WidgetTestRepository(),
      tagRepository: _WidgetTestTagRepository(),
    );
    final settingsController = SettingsViewModel(
      settingsRepository: _WidgetTestSettingsRepository(),
      loginItemRepository: _WidgetTestLoginItemRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
    );
    final windowBridge = _WidgetTestWindowBridge();
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: controller,
      windowBridge: windowBridge,
    );
    await controller.load();
    await settingsController.load();
    await updateController.load();
    await stickyBoardController.load();

    await tester.pumpWidget(
      FloatickApp(
        controller: controller,
        settingsController: settingsController,
        updateController: updateController,
        stickyBoardController: stickyBoardController,
        stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
        windowBridge: windowBridge,
        locale: const Locale('en'),
      ),
    );

    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();

    expect(find.text('All clear for today'), findsOneWidget);
    expect(find.text('Search todos'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('add-todo-button')),
        matching: find.text('New'),
      ),
      findsOneWidget,
    );
    expect(find.text('今天已经清空'), findsNothing);

    await controller.add('Write English release notes');
    await tester.pumpAndSettle();
    expect(find.text('1 task remaining'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Window'), findsOneWidget);
    expect(find.text('Keep above other apps'), findsOneWidget);
    expect(find.text('Collapse when clicking outside'), findsOneWidget);
    expect(find.text('Startup'), findsOneWidget);
    expect(find.text('Open at login'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
    expect(find.text('Automatic checks'), findsOneWidget);
    expect(find.text('Check now'), findsOneWidget);
    expect(find.text('Working directory'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings switch the interface and native menu language', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TodoViewModel(
      todoRepository: _WidgetTestRepository(),
      tagRepository: _WidgetTestTagRepository(),
    );
    final settingsRepository = _WidgetTestSettingsRepository();
    final settingsController = SettingsViewModel(
      settingsRepository: settingsRepository,
      loginItemRepository: _WidgetTestLoginItemRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
    );
    final windowBridge = _WidgetTestWindowBridge();
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: controller,
      windowBridge: windowBridge,
    );
    await controller.load();
    await settingsController.load();
    await updateController.load();
    await stickyBoardController.load();

    await tester.pumpWidget(
      FloatickApp(
        controller: controller,
        settingsController: settingsController,
        updateController: updateController,
        stickyBoardController: stickyBoardController,
        stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
        windowBridge: windowBridge,
      ),
    );
    await tester.pump();

    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('language-system')))
          .isSelected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('language-zh')));
    await tester.pumpAndSettle();

    expect(find.text('语言'), findsOneWidget);
    expect(find.text('工作目录'), findsOneWidget);
    expect(
      settingsController.languagePreference,
      AppLanguagePreference.simplifiedChinese,
    );
    expect(
      settingsRepository.savedSettings.languagePreference,
      AppLanguagePreference.simplifiedChinese,
    );

    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Working directory'), findsOneWidget);
    expect(
      settingsController.languagePreference,
      AppLanguagePreference.english,
    );
    expect(windowBridge.preferredLanguageValues, <String?>[null, 'zh', 'en']);
  });
}

class _WidgetTestSettingsRepository implements SettingsRepository {
  AppSettings savedSettings = const AppSettings();

  @override
  String get storagePath => '/tmp/floatick-widget-test/settings.json';

  @override
  Future<AppSettings> load() async => savedSettings;

  @override
  Future<void> save(AppSettings settings) async {
    savedSettings = settings;
  }
}

class _WidgetTestLoginItemRepository implements LoginItemRepository {
  LoginItemStatus status = LoginItemStatus.disabled;
  LoginItemStatus? nextStatus;
  bool failNextUpdate = false;
  final List<bool> setEnabledValues = <bool>[];

  @override
  Future<LoginItemStatus> loadStatus() async => status;

  @override
  Future<LoginItemStatus> setEnabled(bool enabled) async {
    setEnabledValues.add(enabled);
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

class _WidgetTestNoteRepository implements NoteRepository {
  List<NoteItem> savedItems = <NoteItem>[];

  @override
  String get storagePath => '/tmp/floatick-widget-test/notes.json';

  @override
  Future<List<NoteItem>> load() async => List<NoteItem>.of(savedItems);

  @override
  Future<void> save(List<NoteItem> items) async {
    savedItems = List<NoteItem>.of(items);
  }
}

class _WidgetTestRepository implements TodoRepository {
  List<TodoItem> savedItems = <TodoItem>[];

  @override
  String get storagePath => '/tmp/floatick-widget-test/todos.json';

  @override
  Future<List<TodoItem>> load() async {
    return List<TodoItem>.of(savedItems);
  }

  @override
  Future<void> save(List<TodoItem> items) async {
    savedItems = List<TodoItem>.of(items);
  }
}

class _WidgetTestTagRepository implements TagRepository {
  TagWorkspace savedWorkspace = TagWorkspace.empty();

  @override
  String get storagePath => '/tmp/floatick-widget-test/tags.json';

  @override
  Future<TagWorkspace> load() async => savedWorkspace;

  @override
  Future<void> save(TagWorkspace workspace) async {
    savedWorkspace = workspace;
  }
}

class _WidgetTestStickyBoardRepository implements StickyBoardRepository {
  StickyBoardWorkspace savedWorkspace = StickyBoardWorkspace.empty();
  bool failNextSave = false;

  @override
  String get storagePath => '/tmp/floatick-widget-test/sticky_boards.json';

  @override
  Future<StickyBoardWorkspace> load() async => savedWorkspace;

  @override
  Future<void> save(StickyBoardWorkspace workspace) async {
    if (failNextSave) {
      failNextSave = false;
      throw const StorageFailure(kind: StorageFailureKind.write);
    }
    savedWorkspace = workspace;
  }
}

class _WidgetTestUpdateRepository implements UpdateRepository {
  bool automaticallyChecksForUpdates = true;
  bool feedUnavailable = false;
  int checkCount = 0;

  @override
  Future<UpdateSettingsSnapshot> loadSettings() async {
    return UpdateSettingsSnapshot(
      automaticallyChecksForUpdates: automaticallyChecksForUpdates,
      currentVersion: '0.1.0',
    );
  }

  @override
  Future<void> setAutomaticallyChecksForUpdates(bool enabled) async {
    automaticallyChecksForUpdates = enabled;
  }

  @override
  Future<void> checkForUpdates() async {
    checkCount += 1;
    if (feedUnavailable) {
      throw const UpdateFeedUnavailableException();
    }
  }
}

class _WidgetTestWindowBridge implements WindowBridge {
  final List<bool> expandedValues = <bool>[];
  final List<bool> expandedAnimatedValues = <bool>[];
  final List<int> floatingIconCounts = <int>[];
  final List<String?> preferredLanguageValues = <String?>[];
  final List<String> preferredThemeValues = <String>[];
  final List<bool> alwaysOnTopValues = <bool>[];
  ExpandRequestHandler? expandRequestHandler;
  CollapseRequestHandler? collapseRequestHandler;
  Future<void>? setExpandedBarrier;

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {
    expandRequestHandler = handler;
  }

  @override
  void setCollapseRequestHandler(CollapseRequestHandler? handler) {
    collapseRequestHandler = handler;
  }

  @override
  Future<void> synchronizeCollapsedState() async {}

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    return WindowExpansionAnchor.topRight;
  }

  @override
  Future<void> setExpanded(bool expanded, {bool animated = true}) async {
    expandedValues.add(expanded);
    expandedAnimatedValues.add(animated);
    await setExpandedBarrier;
  }

  @override
  Future<void> setFloatingIconCount(int activeCount) async {
    floatingIconCounts.add(activeCount);
  }

  @override
  Future<void> setPreferredLanguage(String? languageCode) async {
    preferredLanguageValues.add(languageCode);
  }

  @override
  Future<void> setPreferredTheme(String themePreference) async {
    preferredThemeValues.add(themePreference);
  }

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    alwaysOnTopValues.add(alwaysOnTop);
  }

  @override
  Future<void> configureBorderlessSecondaryWindow(
    int viewId, {
    bool positionAdjacentToMainWindow = false,
  }) async {}

  @override
  Future<void> revealBorderlessSecondaryWindow(int viewId) async {}
}
