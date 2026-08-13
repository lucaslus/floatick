import 'package:floatick/core/platform/window_bridge.dart';
import 'package:floatick/features/todos/data/tag_repository.dart';
import 'package:floatick/features/todos/data/todo_repository.dart';
import 'package:floatick/features/todos/domain/tag_workspace.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/presentation/deadline_reminder_scheduler.dart';
import 'package:floatick/features/todos/presentation/todo_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an overdue deadline is shown once and marked delivered', () async {
    final now = DateTime.utc(2026, 8, 7, 10);
    final repository = _MemoryTodoRepository(<TodoItem>[
      TodoItem(
        id: 'todo-1',
        title: 'Ship release',
        createdAt: now.subtract(const Duration(days: 1)),
        dueAt: now.subtract(const Duration(minutes: 1)),
        reminderAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);
    final viewModel = TodoViewModel(
      todoRepository: repository,
      tagRepository: _MemoryTagRepository(),
      clock: () => now,
    );
    await viewModel.load();
    final bridge = _MemoryDeadlineReminderBridge();
    final scheduler = DeadlineReminderScheduler(
      todoViewModel: viewModel,
      bridge: bridge,
      onOpenTodo: (_) {},
      clock: () => now,
    );

    await _flushAsyncWork();

    expect(bridge.payloads, hasLength(1));
    expect(bridge.payloads.single.todoId, 'todo-1');
    expect(viewModel.items.single.deadlineNotifiedAt, now);
    expect(viewModel.items.single.reminderNotifiedAt, now);
    scheduler.dispose();
  });

  test('native open action opens the todo and dismiss is a no-op', () async {
    final now = DateTime.utc(2026, 8, 7, 10);
    final repository = _MemoryTodoRepository(<TodoItem>[
      TodoItem(
        id: 'todo-1',
        title: 'Ship release',
        createdAt: now.subtract(const Duration(days: 1)),
        dueAt: now.add(const Duration(hours: 1)),
      ),
    ]);
    final viewModel = TodoViewModel(
      todoRepository: repository,
      tagRepository: _MemoryTagRepository(),
      clock: () => now,
    );
    await viewModel.load();
    final bridge = _MemoryDeadlineReminderBridge();
    final openedTodoIds = <String>[];
    final scheduler = DeadlineReminderScheduler(
      todoViewModel: viewModel,
      bridge: bridge,
      onOpenTodo: openedTodoIds.add,
      clock: () => now,
    );

    bridge.send(
      const DeadlineReminderAction(
        kind: DeadlineReminderActionKind.open,
        todoId: 'todo-1',
      ),
    );
    expect(openedTodoIds, <String>['todo-1']);
    bridge.send(
      const DeadlineReminderAction(
        kind: DeadlineReminderActionKind.dismiss,
        todoId: 'todo-1',
      ),
    );
    expect(openedTodoIds, <String>['todo-1']);
    expect(viewModel.items.single.isCompleted, isFalse);
    expect(viewModel.items.single.snoozedUntil, isNull);
    scheduler.dispose();
  });

  testWidgets('resume dispatches a deadline missed while inactive', (
    WidgetTester tester,
  ) async {
    var now = DateTime.utc(2026, 8, 7, 10);
    final repository = _MemoryTodoRepository(<TodoItem>[
      TodoItem(
        id: 'todo-1',
        title: 'Ship release',
        createdAt: now.subtract(const Duration(days: 1)),
        dueAt: now.add(const Duration(hours: 1)),
      ),
    ]);
    final viewModel = TodoViewModel(
      todoRepository: repository,
      tagRepository: _MemoryTagRepository(),
      clock: () => now,
    );
    await viewModel.load();
    final bridge = _MemoryDeadlineReminderBridge();
    final scheduler = DeadlineReminderScheduler(
      todoViewModel: viewModel,
      bridge: bridge,
      onOpenTodo: (_) {},
      clock: () => now,
    );

    now = now.add(const Duration(hours: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    for (var index = 0; index < 8; index++) {
      await tester.pump();
    }

    expect(bridge.payloads, hasLength(1));
    expect(viewModel.items.single.deadlineNotifiedAt, now);
    scheduler.dispose();
  });

  test('native delivery marks a reminder while Flutter is inactive', () async {
    var now = DateTime.utc(2026, 8, 7, 10);
    final repository = _MemoryTodoRepository(<TodoItem>[
      TodoItem(
        id: 'todo-1',
        title: 'Ship release',
        createdAt: now.subtract(const Duration(days: 1)),
        dueAt: now.add(const Duration(hours: 1)),
      ),
    ]);
    final viewModel = TodoViewModel(
      todoRepository: repository,
      tagRepository: _MemoryTagRepository(),
      clock: () => now,
    );
    await viewModel.load();
    final bridge = _MemoryDeadlineReminderBridge();
    final scheduler = DeadlineReminderScheduler(
      todoViewModel: viewModel,
      bridge: bridge,
      onOpenTodo: (_) {},
      clock: () => now,
    );

    final scheduled = bridge.scheduledBatches.last.single;
    expect(scheduled.triggerAt, now.add(const Duration(hours: 1)));
    expect(scheduled.deliveryKind, DeadlineReminderDeliveryKind.deadline);

    now = now.add(const Duration(hours: 2));
    bridge.deliveryHandler?.call(
      const DeadlineReminderDelivery(
        notificationId: 'stale-notification',
        todoId: 'todo-1',
        kind: DeadlineReminderDeliveryKind.deadline,
      ),
    );
    await _flushAsyncWork();
    expect(viewModel.items.single.deadlineNotifiedAt, isNull);

    bridge.deliver(scheduled);
    await _flushAsyncWork();

    expect(viewModel.items.single.deadlineNotifiedAt, now);
    expect(viewModel.items.single.reminderNotifiedAt, isNull);
    scheduler.dispose();
  });

  test('updating a deadline resynchronizes the native schedule', () async {
    final now = DateTime.utc(2026, 8, 7, 10);
    final repository = _MemoryTodoRepository(<TodoItem>[
      TodoItem(id: 'todo-1', title: 'Ship release', createdAt: now),
    ]);
    final viewModel = TodoViewModel(
      todoRepository: repository,
      tagRepository: _MemoryTagRepository(),
      clock: () => now,
    );
    await viewModel.load();
    final bridge = _MemoryDeadlineReminderBridge();
    final scheduler = DeadlineReminderScheduler(
      todoViewModel: viewModel,
      bridge: bridge,
      onOpenTodo: (_) {},
      clock: () => now,
    );
    expect(bridge.scheduledBatches.last, isEmpty);

    final dueAt = now.add(const Duration(minutes: 1));
    await viewModel.updateSchedule(
      id: 'todo-1',
      schedule: TodoScheduleDraft(dueAt: dueAt),
    );
    await _flushAsyncWork();

    expect(bridge.scheduledBatches.last, hasLength(1));
    expect(bridge.scheduledBatches.last.single.triggerAt, dueAt);
    expect(
      bridge.scheduledBatches.last.single.deliveryKind,
      DeadlineReminderDeliveryKind.deadline,
    );
    scheduler.dispose();
  });
}

Future<void> _flushAsyncWork() async {
  for (var index = 0; index < 8; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _MemoryDeadlineReminderBridge implements DeadlineReminderBridge {
  final List<DeadlineReminderPayload> payloads = <DeadlineReminderPayload>[];
  final List<List<ScheduledDeadlineReminder>> scheduledBatches =
      <List<ScheduledDeadlineReminder>>[];
  DeadlineReminderActionHandler? handler;
  DeadlineReminderDeliveryHandler? deliveryHandler;

  @override
  void setDeadlineReminderActionHandler(DeadlineReminderActionHandler? value) {
    handler = value;
  }

  @override
  void setDeadlineReminderDeliveryHandler(
    DeadlineReminderDeliveryHandler? value,
  ) {
    deliveryHandler = value;
  }

  @override
  Future<void> showDeadlineReminder(DeadlineReminderPayload payload) async {
    payloads.add(payload);
  }

  @override
  Future<void> synchronizeScheduledDeadlineReminders(
    List<ScheduledDeadlineReminder> reminders,
  ) async {
    scheduledBatches.add(List<ScheduledDeadlineReminder>.of(reminders));
  }

  void send(DeadlineReminderAction action) => handler?.call(action);

  void deliver(ScheduledDeadlineReminder reminder) {
    deliveryHandler?.call(
      DeadlineReminderDelivery(
        notificationId: reminder.notificationId,
        todoId: reminder.payload.todoId,
        kind: reminder.deliveryKind,
      ),
    );
  }
}

class _MemoryTodoRepository implements TodoRepository {
  _MemoryTodoRepository(this.items);

  List<TodoItem> items;

  @override
  String get storagePath => '/tmp/floatick-scheduler-test/todos.json';

  @override
  Future<List<TodoItem>> load() async => List.of(items);

  @override
  Future<void> save(List<TodoItem> updated) async {
    items = List.of(updated);
  }
}

class _MemoryTagRepository implements TagRepository {
  @override
  String get storagePath => '/tmp/floatick-scheduler-test/tags.json';

  @override
  Future<TagWorkspace> load() async => TagWorkspace.empty();

  @override
  Future<void> save(TagWorkspace workspace) async {}
}
