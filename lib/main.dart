import 'package:flutter/widgets.dart';

import 'app/floatick_app.dart';
import 'core/platform/window_bridge.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_view_model.dart';
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
  );
  final updateController = UpdateViewModel(
    updateRepository: MethodChannelUpdateRepository(),
  );
  await Future.wait<void>(<Future<void>>[
    controller.load(),
    settingsController.load(),
    updateController.load(),
  ]);

  runApp(
    FloatickApp(
      controller: controller,
      settingsController: settingsController,
      updateController: updateController,
      windowBridge: MethodChannelWindowBridge(),
    ),
  );
}
