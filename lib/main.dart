import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'app/floatick_app.dart';
import 'core/platform/window_bridge.dart';
import 'features/notes/data/note_repository.dart';
import 'features/notes/presentation/note_view_model.dart';
import 'features/settings/data/login_item_repository.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_view_model.dart';
import 'features/todos/data/first_run_workspace_seeder.dart';
import 'features/todos/data/tag_repository.dart';
import 'features/todos/data/todo_repository.dart';
import 'features/todos/presentation/todo_view_model.dart';
import 'features/updates/data/update_repository.dart';
import 'features/updates/presentation/update_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final windowBridge = MethodChannelWindowBridge();
  try {
    await windowBridge.synchronizeCollapsedState();
  } on Object catch (error, stackTrace) {
    debugPrint('Floatick could not synchronize the native window: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  final todoRepository = LocalTodoRepository();
  final noteController = NoteViewModel(repository: LocalNoteRepository());
  final tagRepository = LocalTagRepository();
  final controller = TodoViewModel(
    todoRepository: todoRepository,
    tagRepository: tagRepository,
    firstRunWorkspaceSeeder: FirstRunWorkspaceSeeder(
      todoRepository: todoRepository,
      tagRepository: tagRepository,
      languageCode: PlatformDispatcher.instance.locale.languageCode,
    ),
  );
  final settingsController = SettingsViewModel(
    settingsRepository: LocalSettingsRepository(),
    loginItemRepository: MethodChannelLoginItemRepository(),
  );
  final updateController = UpdateViewModel(
    updateRepository: MethodChannelUpdateRepository(),
  );
  await Future.wait<void>(<Future<void>>[
    controller.load(),
    noteController.load(),
    settingsController.load(),
    updateController.load(),
  ]);

  runApp(
    FloatickApp(
      controller: controller,
      noteController: noteController,
      settingsController: settingsController,
      updateController: updateController,
      windowBridge: windowBridge,
    ),
  );
}
