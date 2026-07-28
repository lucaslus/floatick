import 'package:flutter/widgets.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

import 'app/floatick_app.dart';
import 'core/platform/window_bridge.dart';
import 'features/settings/data/login_item_repository.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_view_model.dart';
import 'features/sticky_boards/data/sticky_board_repository.dart';
import 'features/sticky_boards/presentation/sticky_board_view_model.dart';
import 'features/sticky_boards/presentation/sticky_board_window_coordinator.dart';
import 'features/todos/data/tag_repository.dart';
import 'features/todos/data/todo_repository.dart';
import 'features/todos/presentation/todo_view_model.dart';
import 'features/updates/data/update_repository.dart';
import 'features/updates/presentation/update_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = TodoViewModel(
    todoRepository: LocalTodoRepository(),
    tagRepository: LocalTagRepository(),
  );
  final settingsController = SettingsViewModel(
    settingsRepository: LocalSettingsRepository(),
    loginItemRepository: MethodChannelLoginItemRepository(),
  );
  final updateController = UpdateViewModel(
    updateRepository: MethodChannelUpdateRepository(),
  );
  final stickyBoardController = StickyBoardViewModel(
    repository: LocalStickyBoardRepository(),
  );
  await Future.wait<void>(<Future<void>>[
    controller.load(),
    settingsController.load(),
    updateController.load(),
    stickyBoardController.load(),
  ]);
  final windowBridge = MethodChannelWindowBridge();
  final stickyBoardWindowCoordinator = StickyBoardWindowCoordinator(
    boardController: stickyBoardController,
    todoController: controller,
    windowBridge: windowBridge,
  );

  runMultiApp(
    home: (context, viewId) => FloatickApp(
      controller: controller,
      settingsController: settingsController,
      updateController: updateController,
      stickyBoardController: stickyBoardController,
      stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
      windowBridge: windowBridge,
    ),
  );
}
