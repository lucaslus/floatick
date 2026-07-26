import 'package:floatick/app/floatick_app.dart';
import 'package:floatick/core/platform/window_bridge.dart';
import 'package:floatick/core/ui/floatick_brand_mark.dart';
import 'package:floatick/features/settings/data/settings_repository.dart';
import 'package:floatick/features/settings/domain/app_settings.dart';
import 'package:floatick/features/settings/presentation/settings_view_model.dart';
import 'package:floatick/features/sticky_boards/data/sticky_board_repository.dart';
import 'package:floatick/features/sticky_boards/domain/sticky_board_workspace.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_view_model.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_window_coordinator.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:floatick/features/todos/presentation/widgets/floating_todo_icon.dart';
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
    final windowBridge = _WidgetTestWindowBridge();
    final settingsRepository = _WidgetTestSettingsRepository();
    final settingsController = SettingsViewModel(
      settingsRepository: settingsRepository,
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
        locale: const Locale('zh'),
      ),
    );
    expect(find.byKey(const ValueKey('floating-todo-icon')), findsOneWidget);
    expect(find.byType(FloatickBrandMark), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('floating-todo-icon'))),
      const Size.square(FloatingTodoIcon.canvasDimension),
    );

    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topRight);
    await tester.pumpAndSettle();

    expect(windowBridge.expandedValues, <bool>[true]);
    expect(find.text('Floatick'), findsNothing);
    expect(find.text('今天已经清空'), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-brand-mark')), findsOneWidget);
    expect(find.byKey(const Key('search-field')), findsOneWidget);
    expect(find.byKey(const Key('tag-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('add-todo-button')), findsOneWidget);
    final searchRect = tester.getRect(find.byKey(const Key('search-field')));
    final tagFilterRect = tester.getRect(
      find.byKey(const Key('tag-filter-button')),
    );
    expect(tagFilterRect.left, greaterThan(searchRect.right));
    expect((tagFilterRect.center.dy - searchRect.center.dy).abs(), lessThan(1));
    expect(tagFilterRect.size, const Size.square(42));
    final panelSurface = tester.widget<DecoratedBox>(
      find.byKey(const Key('todo-panel-surface')),
    );
    final panelDecoration = panelSurface.decoration as BoxDecoration;
    expect(panelDecoration.boxShadow, isNull);
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('settings-drawer-slide')))
          .offset,
      const Offset(1, 0),
    );
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
          .offset,
      const Offset(0, 1),
    );

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-drawer')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
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
    expect(find.byType(Switch), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('automatic-update-toggle'))),
      const Size(32, 18),
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

    await tester.tap(find.byKey(const Key('view-todo-new-todo')));
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

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
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

    final editButton = find.byKey(const Key('edit-todo-new-todo'));
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
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

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(windowBridge.expandedValues, <bool>[true, false]);
    expect(find.byKey(const ValueKey('floating-todo-icon')), findsOneWidget);
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
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
    );
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: controller,
    );
    final windowBridge = _WidgetTestWindowBridge();
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
          .widget<TextFormField>(find.byKey(const Key('todo-title-field')))
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
    expect(
      (tester
                  .widget<IconButton>(
                    find.byKey(const Key('assign-tags-todo-1')),
                  )
                  .icon
              as Icon)
          .icon,
      Icons.sell_rounded,
    );
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
    expect(
      (tester
                  .widget<IconButton>(
                    find.byKey(const Key('assign-tags-todo-1')),
                  )
                  .icon
              as Icon)
          .icon,
      Icons.sell_rounded,
    );

    await tester.tap(find.byKey(const Key('add-todo-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Other task',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tag-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-filter-tag-work')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-tag-filter')), findsOneWidget);
    expect(find.text('Tagged task').hitTestable(), findsOneWidget);
    expect(find.text('Other task').hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('collapse-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('floating-todo-icon')), findsOneWidget);
    windowBridge.expandRequestHandler?.call(WindowExpansionAnchor.topLeft);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tag-filter-button')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopRight(find.byKey(const Key('tag-filter-drawer'))).dx,
      tester.getTopRight(find.byKey(const Key('todo-panel-surface'))).dx,
    );
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
    tester.view.physicalSize = const Size(500, 760);
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
      ];
    var todoSequence = 0;
    final todoController = TodoViewModel(
      todoRepository: todoRepository,
      tagRepository: _WidgetTestTagRepository(),
      idGenerator: () => 'created-todo-${++todoSequence}',
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
      idGenerator: () => 'board-launch',
    );
    final settingsController = SettingsViewModel(
      settingsRepository: _WidgetTestSettingsRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final windowBridge = _WidgetTestWindowBridge();
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: todoController,
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
    expect(find.byKey(const Key('sticky-board-board-launch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sticky-board-board-launch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sticky-board-detail-drawer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sticky-board-add-existing')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('sticky-board-todo-picker-drawer')),
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

    await tester.tap(find.byKey(const Key('sticky-board-new-todo')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Share the release notes',
    );
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
      todoController.items.map((item) => item.id),
      contains('created-todo-1'),
    );
    expect(stickyBoardController.todoCountForBoard('board-launch'), 2);
    expect(stickyBoardController.todoIdsForBoard('board-launch'), <String>[
      'existing-todo',
      'created-todo-1',
    ]);
    expect(find.text('Share the release notes'), findsWidgets);
    expect(tester.takeException(), isNull);
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
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
    );
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: controller,
    );
    final windowBridge = _WidgetTestWindowBridge();
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
        matching: find.text('Add todo'),
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
    );
    final updateController = UpdateViewModel(
      updateRepository: _WidgetTestUpdateRepository(),
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: _WidgetTestStickyBoardRepository(),
    );
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: controller,
    );
    final windowBridge = _WidgetTestWindowBridge();
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

  @override
  String get storagePath => '/tmp/floatick-widget-test/sticky_boards.json';

  @override
  Future<StickyBoardWorkspace> load() async => savedWorkspace;

  @override
  Future<void> save(StickyBoardWorkspace workspace) async {
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
  final List<String?> preferredLanguageValues = <String?>[];
  ExpandRequestHandler? expandRequestHandler;

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {
    expandRequestHandler = handler;
  }

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    return WindowExpansionAnchor.topRight;
  }

  @override
  Future<void> setExpanded(bool expanded) async {
    expandedValues.add(expanded);
  }

  @override
  Future<void> setPreferredLanguage(String? languageCode) async {
    preferredLanguageValues.add(languageCode);
  }
}
