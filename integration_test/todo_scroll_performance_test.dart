import 'dart:convert';

import 'package:floatick/app/theme/floatick_theme.dart';
import 'package:floatick/core/platform/window_bridge.dart';
import 'package:floatick/features/settings/data/login_item_repository.dart';
import 'package:floatick/features/settings/data/settings_repository.dart';
import 'package:floatick/features/settings/domain/app_settings.dart';
import 'package:floatick/features/settings/domain/login_item_status.dart';
import 'package:floatick/features/settings/presentation/settings_view_model.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/presentation/todo_panel.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:floatick/features/updates/data/update_repository.dart';
import 'package:floatick/features/updates/domain/update_settings_snapshot.dart';
import 'package:floatick/features/updates/presentation/update_view_model.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Profile-mode UI benchmark for a 10,000-item workspace.
///
/// Run it explicitly on macOS:
/// `flutter drive --profile -d macos \
///   --driver=test_driver/performance_test_driver.dart \
///   --target=integration_test/todo_scroll_performance_test.dart`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scrolls a 10,000-item todo list', (tester) async {
    tester.view.physicalSize = const Size(500, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final createdAt = DateTime.utc(2026, 7, 29, 8);
    final todoController = TodoViewModel(
      todoRepository: _BenchmarkTodoRepository(
        List<TodoItem>.generate(
          10000,
          (index) => TodoItem(
            id: 'todo-$index',
            title: 'Performance todo $index',
            createdAt: createdAt.add(Duration(seconds: index)),
          ),
          growable: false,
        ),
      ),
      tagRepository: _BenchmarkTagRepository(),
    );
    final settingsController = SettingsViewModel(
      settingsRepository: _BenchmarkSettingsRepository(),
      loginItemRepository: _BenchmarkLoginItemRepository(),
    );
    final updateController = UpdateViewModel(
      updateRepository: _BenchmarkUpdateRepository(),
    );
    final windowBridge = _BenchmarkWindowBridge();
    addTearDown(todoController.dispose);
    addTearDown(settingsController.dispose);
    addTearDown(updateController.dispose);

    await Future.wait<void>(<Future<void>>[
      todoController.load(),
      settingsController.load(),
      updateController.load(),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloatickTheme(Brightness.light),
        darkTheme: buildFloatickTheme(Brightness.dark),
        home: Center(
          child: TodoPanel(
            controller: todoController,
            settingsController: settingsController,
            updateController: updateController,
            windowBridge: windowBridge,
            expansionAnchor: WindowExpansionAnchor.topRight,
            onCollapse: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = find.byType(ListView).first;
    expect(list, findsOneWidget);
    await tester.fling(list, const Offset(0, -600), 1800);
    await tester.pumpAndSettle();

    await binding.watchPerformance(() async {
      for (var iteration = 0; iteration < 8; iteration++) {
        await tester.fling(list, const Offset(0, -900), 2200);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'todo_scroll_10000');

    final result = binding.reportData?['todo_scroll_10000'];
    expect(result, isA<Map<String, dynamic>>());
    debugPrint(const JsonEncoder.withIndent('  ').convert(result));
  });
}

class _BenchmarkTodoRepository implements TodoRepository {
  _BenchmarkTodoRepository(this.items);

  List<TodoItem> items;

  @override
  String get storagePath => '/tmp/floatick-scroll-benchmark/todos.json';

  @override
  Future<List<TodoItem>> load() async => List<TodoItem>.of(items);

  @override
  Future<void> save(List<TodoItem> items) async {
    this.items = List<TodoItem>.of(items);
  }
}

class _BenchmarkTagRepository implements TagRepository {
  @override
  String get storagePath => '/tmp/floatick-scroll-benchmark/tags.json';

  @override
  Future<TagWorkspace> load() async => TagWorkspace.empty();

  @override
  Future<void> save(TagWorkspace workspace) async {}
}

class _BenchmarkSettingsRepository implements SettingsRepository {
  @override
  String get storagePath => '/tmp/floatick-scroll-benchmark/settings.json';

  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

class _BenchmarkLoginItemRepository implements LoginItemRepository {
  @override
  Future<LoginItemStatus> loadStatus() async => LoginItemStatus.disabled;

  @override
  Future<LoginItemStatus> setEnabled(bool enabled) async {
    return enabled ? LoginItemStatus.enabled : LoginItemStatus.disabled;
  }
}

class _BenchmarkUpdateRepository implements UpdateRepository {
  @override
  Future<UpdateSettingsSnapshot> loadSettings() async {
    return const UpdateSettingsSnapshot(
      automaticallyChecksForUpdates: false,
      currentVersion: 'benchmark',
    );
  }

  @override
  Future<void> setAutomaticallyChecksForUpdates(bool enabled) async {}

  @override
  Future<void> checkForUpdates() async {}
}

class _BenchmarkWindowBridge implements WindowBridge {
  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {}

  @override
  void setCollapseRequestHandler(CollapseRequestHandler? handler) {}

  @override
  Future<void> synchronizeCollapsedState() async {}

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    return WindowExpansionAnchor.topRight;
  }

  @override
  Future<void> setExpanded(bool expanded, {bool animated = true}) async {}

  @override
  Future<void> setFloatingIconCount(int activeCount) async {}

  @override
  Future<void> setPreferredLanguage(String? languageCode) async {}

  @override
  Future<void> setPreferredTheme(String themePreference) async {}

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {}
}
