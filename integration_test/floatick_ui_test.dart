import 'dart:io';

import 'package:floatick/app/floatick_app.dart';
import 'package:floatick/core/platform/window_bridge.dart';
import 'package:floatick/features/settings/data/login_item_repository.dart';
import 'package:floatick/features/settings/data/settings_repository.dart';
import 'package:floatick/features/settings/domain/login_item_status.dart';
import 'package:floatick/features/settings/presentation/settings_view_model.dart';
import 'package:floatick/features/sticky_boards/data/sticky_board_repository.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_view_model.dart';
import 'package:floatick/features/sticky_boards/presentation/sticky_board_window_coordinator.dart';
import 'package:floatick/features/todos/data/first_run_workspace_seeder.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:floatick/features/updates/data/update_repository.dart';
import 'package:floatick/features/updates/domain/update_settings_snapshot.dart';
import 'package:floatick/features/updates/presentation/update_view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Floatick macOS user journeys', () {
    testWidgets('first run, todo lifecycle, keyboard input, and persistence', (
      tester,
    ) async {
      final harness = await _UiTestHarness.create();
      addTearDown(() => harness.dispose(tester));

      await harness.pumpApp(tester);

      expect(find.text('Welcome to Floatick'), findsOneWidget);
      expect(find.text('Try completing this todo'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Start here'), findsOneWidget);
      expect(await File(harness.todoRepository.storagePath).exists(), isTrue);
      expect(await File(harness.tagRepository.storagePath).exists(), isTrue);

      await tester.tap(find.byKey(const Key('add-todo-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('todo-title-field')),
        'Ship the UI automation suite',
      );
      await tester.enterText(
        find.byKey(const Key('todo-content-field')),
        '## Acceptance\n\n- Works on macOS\n- Persists locally',
      );
      await tester.tap(find.byKey(const Key('save-todo-details')));
      await tester.pumpAndSettle();

      expect(
        find.text('Ship the UI automation suite').hitTestable(),
        findsOneWidget,
      );
      expect(harness.todoController.activeCount, 3);
      expect(harness.windowBridge.floatingIconCounts.last, 3);

      final detailsTarget = find.byKey(
        const Key('todo-open-details-region-ui-todo-1'),
      );
      await tester.tap(detailsTarget);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(detailsTarget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('todo-details-markdown')), findsOneWidget);
      expect(find.text('Acceptance'), findsOneWidget);
      await tester.tap(find.byKey(const Key('todo-drawer-close')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle-todo-ui-todo-1')));
      await tester.pumpAndSettle();
      expect(harness.todoController.itemById('ui-todo-1')?.isCompleted, isTrue);

      await tester.tap(find.byKey(const Key('archive-todo-ui-todo-1')));
      await tester.pumpAndSettle();
      expect(harness.todoController.itemById('ui-todo-1')?.isArchived, isTrue);
      await tester.tap(find.byKey(const Key('archive-scope-button')));
      await tester.pumpAndSettle();
      expect(find.text('Archive · 1'), findsOneWidget);
      expect(
        find.text('Ship the UI automation suite').hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('restore-todo-ui-todo-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive-scope-button')));
      await tester.pumpAndSettle();
      expect(
        find.text('Ship the UI automation suite').hitTestable(),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('search-field')),
        'automation',
      );
      await tester.pump();
      expect(find.text('Ship the UI automation suite'), findsOneWidget);
      expect(find.text('Welcome to Floatick'), findsNothing);

      final reloadedController = TodoViewModel(
        todoRepository: LocalTodoRepository(
          rootDirectory: harness.rootDirectory,
        ),
        tagRepository: LocalTagRepository(rootDirectory: harness.rootDirectory),
      );
      await reloadedController.load();
      addTearDown(reloadedController.dispose);
      expect(
        reloadedController.itemById('ui-todo-1')?.content,
        '## Acceptance\n\n- Works on macOS\n- Persists locally',
      );
      expect(reloadedController.itemById('ui-todo-1')?.isCompleted, isTrue);
      expect(reloadedController.itemById('ui-todo-1')?.isArchived, isFalse);
    });

    testWidgets('tag assignment and multi-select filtering', (tester) async {
      final harness = await _UiTestHarness.create(seedWelcomeWorkspace: false);
      addTearDown(() => harness.dispose(tester));
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const Key('tag-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manage-tags-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('tag-search-create-field')),
        'Work',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tag-search-create-field')),
        'Personal',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(harness.todoController.tags.map((tag) => tag.name), <String>[
        'Work',
        'Personal',
      ]);
      await tester.tap(find.byKey(const Key('tag-management-close')));
      await tester.pumpAndSettle();

      await _createTodoWithTags(
        tester,
        title: 'Prepare release notes',
        tagIds: const <String>['ui-tag-1'],
      );
      await _createTodoWithTags(
        tester,
        title: 'Book a design review',
        tagIds: const <String>['ui-tag-2'],
      );
      await _createTodoWithTags(
        tester,
        title: 'Unfiltered task',
        tagIds: const <String>[],
      );

      await tester.tap(find.byKey(const Key('tag-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tag-filter-ui-tag-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tag-filter-ui-tag-2')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('tag-filter-count')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('tag-filter-close')));
      await tester.pumpAndSettle();

      expect(find.text('Prepare release notes').hitTestable(), findsOneWidget);
      expect(find.text('Book a design review').hitTestable(), findsOneWidget);
      expect(find.text('Unfiltered task').hitTestable(), findsNothing);

      await tester.tap(find.byKey(const Key('tag-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tag-filter-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tag-filter-close')));
      await tester.pumpAndSettle();
      expect(find.text('Unfiltered task').hitTestable(), findsOneWidget);
    });

    testWidgets('sticky boards and settings retain their native boundaries', (
      tester,
    ) async {
      final harness = await _UiTestHarness.create(seedWelcomeWorkspace: false);
      addTearDown(() => harness.dispose(tester));
      await harness.todoController.create('Review the launch checklist');
      await harness.pumpApp(tester);

      await tester.tap(find.byKey(const Key('sticky-boards-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sticky-board-search-create-field')),
        'Launch',
      );
      await tester.tap(find.byKey(const Key('submit-sticky-board')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('sticky-board-thumbnail-ui-board-1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('sticky-board-ui-board-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sticky-board-add-existing')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sticky-board-picker-ui-todo-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to Sticky Boards'));
      await tester.pumpAndSettle();
      expect(
        harness.stickyBoardController.todoIdsForBoard('ui-board-1'),
        <String>['ui-todo-1'],
      );

      await tester.tap(find.byKey(const Key('sticky-board-pin')));
      await tester.pumpAndSettle();
      expect(harness.launchedBoards, <String>['ui-board-1']);
      expect(
        harness.stickyBoardController.boardById('ui-board-1')?.isPinned,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('sticky-board-pin')));
      await tester.pumpAndSettle();
      expect(harness.hiddenBoards, <String>['ui-board-1']);
      expect(
        harness.stickyBoardController.boardById('ui-board-1')?.isPinned,
        isFalse,
      );

      await tester.tap(find.byTooltip('Close Sticky Boards'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('always-on-top-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-at-login-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme-light')));
      await tester.pumpAndSettle();

      expect(harness.settingsController.alwaysOnTop, isFalse);
      expect(harness.settingsController.openAtLogin, isTrue);
      expect(harness.loginItemRepository.enabledValues, <bool>[true]);
      expect(harness.windowBridge.alwaysOnTopValues.last, isFalse);
      expect(harness.windowBridge.preferredThemeValues.last, 'light');
    });
  });
}

Future<void> _createTodoWithTags(
  WidgetTester tester, {
  required String title,
  required List<String> tagIds,
}) async {
  await tester.tap(find.byKey(const Key('add-todo-button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('todo-title-field')), title);
  await tester.pump();
  if (tagIds.isNotEmpty) {
    await tester.tap(find.byKey(const Key('todo-editor-tag-button')));
    await tester.pumpAndSettle();
    for (final tagId in tagIds) {
      await tester.tap(find.byKey(Key('tag-assignment-$tagId')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('tag-assignment-close')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('save-todo-details')));
  await tester.pumpAndSettle();
  expect(find.text(title).hitTestable(), findsOneWidget);
  expect(
    tester
        .widget<AnimatedSlide>(find.byKey(const Key('todo-drawer-slide')))
        .offset,
    const Offset(0, 1),
  );
}

class _UiTestHarness {
  _UiTestHarness._({
    required this.rootDirectory,
    required this.todoRepository,
    required this.tagRepository,
    required this.todoController,
    required this.settingsController,
    required this.updateController,
    required this.stickyBoardController,
    required this.stickyBoardWindowCoordinator,
    required this.windowBridge,
    required this.loginItemRepository,
    required this.launchedBoards,
    required this.hiddenBoards,
  });

  static Future<_UiTestHarness> create({
    bool seedWelcomeWorkspace = true,
  }) async {
    final rootDirectory = await Directory.systemTemp.createTemp(
      'floatick-ui-test-',
    );
    final todoRepository = LocalTodoRepository(rootDirectory: rootDirectory);
    final tagRepository = LocalTagRepository(rootDirectory: rootDirectory);
    var todoSequence = 0;
    var tagSequence = 0;
    var boardSequence = 0;
    final todoController = TodoViewModel(
      todoRepository: todoRepository,
      tagRepository: tagRepository,
      firstRunWorkspaceSeeder: seedWelcomeWorkspace
          ? FirstRunWorkspaceSeeder(
              todoRepository: todoRepository,
              tagRepository: tagRepository,
              languageCode: 'en',
              clock: () => DateTime.utc(2026, 7, 28, 8),
            )
          : null,
      clock: () => DateTime.utc(2026, 7, 28, 9),
      idGenerator: () => 'ui-todo-${++todoSequence}',
      tagIdGenerator: () => 'ui-tag-${++tagSequence}',
    );
    final settingsController = SettingsViewModel(
      settingsRepository: LocalSettingsRepository(rootDirectory: rootDirectory),
      loginItemRepository: _UiTestLoginItemRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _UiTestUpdateRepository(),
    );
    final stickyBoardController = StickyBoardViewModel(
      repository: LocalStickyBoardRepository(rootDirectory: rootDirectory),
      clock: () => DateTime.utc(2026, 7, 28, 10, boardSequence),
      idGenerator: () => 'ui-board-${++boardSequence}',
    );
    final windowBridge = _UiTestWindowBridge();
    final launchedBoards = <String>[];
    final hiddenBoards = <String>[];
    final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
      boardController: stickyBoardController,
      todoController: todoController,
      windowBridge: windowBridge,
      windowLauncher: (boardId) async => launchedBoards.add(boardId),
      windowHider: (boardId) async => hiddenBoards.add(boardId),
    );
    await Future.wait<void>(<Future<void>>[
      todoController.load(),
      settingsController.load(),
      updateController.load(),
      stickyBoardController.load(),
    ]);
    return _UiTestHarness._(
      rootDirectory: rootDirectory,
      todoRepository: todoRepository,
      tagRepository: tagRepository,
      todoController: todoController,
      settingsController: settingsController,
      updateController: updateController,
      stickyBoardController: stickyBoardController,
      stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
      windowBridge: windowBridge,
      loginItemRepository:
          settingsController.loginItemRepository as _UiTestLoginItemRepository,
      launchedBoards: launchedBoards,
      hiddenBoards: hiddenBoards,
    );
  }

  final Directory rootDirectory;
  final LocalTodoRepository todoRepository;
  final LocalTagRepository tagRepository;
  final TodoViewModel todoController;
  final SettingsViewModel settingsController;
  final UpdateViewModel updateController;
  final StickyBoardViewModel stickyBoardController;
  final StickyBoardWindowCoordinator stickyBoardWindowCoordinator;
  final _UiTestWindowBridge windowBridge;
  final _UiTestLoginItemRepository loginItemRepository;
  final List<String> launchedBoards;
  final List<String> hiddenBoards;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 760);
    tester.view.devicePixelRatio = 1;
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
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    todoController.dispose();
    settingsController.dispose();
    updateController.dispose();
    stickyBoardController.dispose();
    if (await rootDirectory.exists()) {
      await rootDirectory.delete(recursive: true);
    }
  }
}

class _UiTestWindowBridge implements WindowBridge {
  ExpandRequestHandler? expandRequestHandler;
  final List<bool> expandedValues = <bool>[];
  final List<int> floatingIconCounts = <int>[];
  final List<String> preferredThemeValues = <String>[];
  final List<bool> alwaysOnTopValues = <bool>[];

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {
    expandRequestHandler = handler;
  }

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    return WindowExpansionAnchor.topRight;
  }

  @override
  Future<void> setExpanded(bool expanded, {bool animated = true}) async {
    expandedValues.add(expanded);
  }

  @override
  Future<void> setFloatingIconCount(int activeCount) async {
    floatingIconCounts.add(activeCount);
  }

  @override
  Future<void> setPreferredLanguage(String? languageCode) async {}

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

class _UiTestLoginItemRepository implements LoginItemRepository {
  LoginItemStatus status = LoginItemStatus.disabled;
  final List<bool> enabledValues = <bool>[];

  @override
  Future<LoginItemStatus> loadStatus() async => status;

  @override
  Future<LoginItemStatus> setEnabled(bool enabled) async {
    enabledValues.add(enabled);
    status = enabled ? LoginItemStatus.enabled : LoginItemStatus.disabled;
    return status;
  }
}

class _UiTestUpdateRepository implements UpdateRepository {
  bool automaticallyChecksForUpdates = true;

  @override
  Future<UpdateSettingsSnapshot> loadSettings() async {
    return UpdateSettingsSnapshot(
      automaticallyChecksForUpdates: automaticallyChecksForUpdates,
      currentVersion: '0.2.0',
    );
  }

  @override
  Future<void> setAutomaticallyChecksForUpdates(bool enabled) async {
    automaticallyChecksForUpdates = enabled;
  }

  @override
  Future<void> checkForUpdates() async {}
}
