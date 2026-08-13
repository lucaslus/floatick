import 'package:floatick/core/platform/window_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('floatick/window');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('coordinates the fixed main window and native floating icon', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final bridge = MethodChannelWindowBridge();

    await bridge.synchronizeCollapsedState();
    await bridge.setFloatingIconCount(7);
    await bridge.setPreferredTheme('dark');
    await bridge.setExpanded(true, animated: false);

    expect(calls.map((call) => call.method), <String>[
      'synchronizeCollapsedState',
      'setFloatingIconCount',
      'setPreferredTheme',
      'setExpanded',
    ]);
    expect(calls[1].arguments, 7);
    expect(calls[2].arguments, 'dark');
    expect(calls.last.arguments, <String, bool>{
      'expanded': true,
      'animated': false,
    });
  });

  test('replays an expand request received before the UI is ready', () async {
    final bridge = MethodChannelWindowBridge();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('requestExpand', 'bottomLeft'),
      ),
      null,
    );

    final receivedAnchors = <WindowExpansionAnchor>[];
    bridge.setExpandRequestHandler(receivedAnchors.add);

    expect(receivedAnchors, <WindowExpansionAnchor>[
      WindowExpansionAnchor.bottomLeft,
    ]);
  });

  test('replays a collapse request received before the UI is ready', () async {
    final bridge = MethodChannelWindowBridge();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('requestCollapse')),
      null,
    );

    var collapseRequestCount = 0;
    bridge.setCollapseRequestHandler(() => collapseRequestCount += 1);

    expect(collapseRequestCount, 1);
  });

  test('sends reminder payloads and decodes native actions', () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final bridge = MethodChannelWindowBridge();
    final actions = <DeadlineReminderAction>[];
    bridge.setDeadlineReminderActionHandler(actions.add);

    await bridge.showDeadlineReminder(
      const DeadlineReminderPayload(
        notificationId: 'todo-1:deadline:1',
        todoId: 'todo-1',
        title: 'Ship release',
        dueLabel: 'Aug 7 · 18:00',
        isOverdue: true,
        isAdvanceReminder: false,
        tagLabel: 'floatick',
      ),
    );
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('deadlineReminderAction', <String, Object>{
          'todoId': 'todo-1',
          'action': 'open',
        }),
      ),
      null,
    );

    expect(calls.single.method, 'showDeadlineReminder');
    expect(calls.single.arguments, <String, Object>{
      'notificationId': 'todo-1:deadline:1',
      'todoId': 'todo-1',
      'title': 'Ship release',
      'dueLabel': 'Aug 7 · 18:00',
      'isOverdue': true,
      'isAdvanceReminder': false,
      'tagLabel': 'floatick',
    });
    expect(actions.single.kind, DeadlineReminderActionKind.open);
    expect(actions.single.todoId, 'todo-1');
  });

  test('synchronizes native schedules and decodes delivery events', () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final bridge = MethodChannelWindowBridge();
    final deliveries = <DeadlineReminderDelivery>[];
    bridge.setDeadlineReminderDeliveryHandler(deliveries.add);
    final triggerAt = DateTime.utc(2026, 8, 7, 10);

    await bridge
        .synchronizeScheduledDeadlineReminders(<ScheduledDeadlineReminder>[
          ScheduledDeadlineReminder(
            notificationId: 'todo-1:deadline:1',
            triggerAt: triggerAt,
            deliveryKind: DeadlineReminderDeliveryKind.deadline,
            payload: const DeadlineReminderPayload(
              notificationId: 'todo-1:deadline:1',
              todoId: 'todo-1',
              title: 'Ship release',
              dueLabel: 'Aug 7 · 18:00',
              isOverdue: false,
              isAdvanceReminder: false,
            ),
          ),
        ]);
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('deadlineReminderDelivered', <String, Object>{
          'notificationId': 'todo-1:deadline:1',
          'todoId': 'todo-1',
          'deliveryKind': 'deadline',
        }),
      ),
      null,
    );

    expect(calls.single.method, 'synchronizeScheduledDeadlineReminders');
    expect(calls.single.arguments, <Map<String, Object>>[
      <String, Object>{
        'notificationId': 'todo-1:deadline:1',
        'triggerAtMilliseconds': triggerAt.millisecondsSinceEpoch,
        'deliveryKind': 'deadline',
        'payload': <String, Object>{
          'notificationId': 'todo-1:deadline:1',
          'todoId': 'todo-1',
          'title': 'Ship release',
          'dueLabel': 'Aug 7 · 18:00',
          'isOverdue': false,
          'isAdvanceReminder': false,
        },
      },
    ]);
    expect(deliveries.single.notificationId, 'todo-1:deadline:1');
    expect(deliveries.single.todoId, 'todo-1');
    expect(deliveries.single.kind, DeadlineReminderDeliveryKind.deadline);
  });
}
