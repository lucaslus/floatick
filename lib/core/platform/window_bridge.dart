import 'package:flutter/services.dart';

enum WindowExpansionAnchor {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  static WindowExpansionAnchor fromWireValue(Object? value) {
    return WindowExpansionAnchor.values.firstWhere(
      (anchor) => anchor.name == value,
      orElse: () => WindowExpansionAnchor.topRight,
    );
  }
}

typedef ExpandRequestHandler =
    void Function(WindowExpansionAnchor expansionAnchor);
typedef CollapseRequestHandler = void Function();

enum DeadlineReminderActionKind { open, dismiss }

enum DeadlineReminderDeliveryKind { snoozed, deadline, advance }

class DeadlineReminderPayload {
  const DeadlineReminderPayload({
    required this.notificationId,
    required this.todoId,
    required this.title,
    required this.dueLabel,
    required this.isOverdue,
    required this.isAdvanceReminder,
    this.tagLabel,
  });

  final String notificationId;
  final String todoId;
  final String title;
  final String dueLabel;
  final bool isOverdue;
  final bool isAdvanceReminder;
  final String? tagLabel;

  Map<String, Object> toMap() {
    return <String, Object>{
      'notificationId': notificationId,
      'todoId': todoId,
      'title': title,
      'dueLabel': dueLabel,
      'isOverdue': isOverdue,
      'isAdvanceReminder': isAdvanceReminder,
      'tagLabel': ?tagLabel,
    };
  }
}

class ScheduledDeadlineReminder {
  const ScheduledDeadlineReminder({
    required this.notificationId,
    required this.triggerAt,
    required this.deliveryKind,
    required this.payload,
  });

  final String notificationId;
  final DateTime triggerAt;
  final DeadlineReminderDeliveryKind deliveryKind;
  final DeadlineReminderPayload payload;

  Map<String, Object> toMap() {
    return <String, Object>{
      'notificationId': notificationId,
      'triggerAtMilliseconds': triggerAt.toUtc().millisecondsSinceEpoch,
      'deliveryKind': deliveryKind.name,
      'payload': payload.toMap(),
    };
  }
}

class DeadlineReminderDelivery {
  const DeadlineReminderDelivery({
    required this.notificationId,
    required this.todoId,
    required this.kind,
  });

  final String notificationId;
  final String todoId;
  final DeadlineReminderDeliveryKind kind;
}

class DeadlineReminderAction {
  const DeadlineReminderAction({required this.kind, required this.todoId});

  final DeadlineReminderActionKind kind;
  final String todoId;
}

typedef DeadlineReminderActionHandler =
    void Function(DeadlineReminderAction action);
typedef DeadlineReminderDeliveryHandler =
    void Function(DeadlineReminderDelivery delivery);

abstract interface class DeadlineReminderBridge {
  void setDeadlineReminderActionHandler(DeadlineReminderActionHandler? handler);

  void setDeadlineReminderDeliveryHandler(
    DeadlineReminderDeliveryHandler? handler,
  );

  Future<void> showDeadlineReminder(DeadlineReminderPayload payload);

  Future<void> synchronizeScheduledDeadlineReminders(
    List<ScheduledDeadlineReminder> reminders,
  );
}

abstract interface class WindowBridge {
  void setExpandRequestHandler(ExpandRequestHandler? handler);

  void setCollapseRequestHandler(CollapseRequestHandler? handler);

  Future<void> synchronizeCollapsedState();

  Future<WindowExpansionAnchor> preferredExpansionAnchor();

  Future<void> setExpanded(bool expanded, {bool animated = true});

  Future<void> setFloatingIconCount(int activeCount);

  Future<void> setPreferredLanguage(String? languageCode);

  Future<void> setPreferredTheme(String themePreference);

  Future<void> setAlwaysOnTop(bool alwaysOnTop);
}

class MethodChannelWindowBridge
    implements WindowBridge, DeadlineReminderBridge {
  MethodChannelWindowBridge([
    this._channel = const MethodChannel('floatick/window'),
  ]) {
    _channel.setMethodCallHandler(_handleNativeMethod);
  }

  final MethodChannel _channel;
  ExpandRequestHandler? _expandRequestHandler;
  CollapseRequestHandler? _collapseRequestHandler;
  DeadlineReminderActionHandler? _deadlineReminderActionHandler;
  DeadlineReminderDeliveryHandler? _deadlineReminderDeliveryHandler;
  WindowExpansionAnchor? _pendingExpansionAnchor;
  bool _pendingCollapseRequest = false;

  @override
  void setDeadlineReminderActionHandler(
    DeadlineReminderActionHandler? handler,
  ) {
    _deadlineReminderActionHandler = handler;
  }

  @override
  void setDeadlineReminderDeliveryHandler(
    DeadlineReminderDeliveryHandler? handler,
  ) {
    _deadlineReminderDeliveryHandler = handler;
  }

  @override
  Future<void> showDeadlineReminder(DeadlineReminderPayload payload) {
    return _channel.invokeMethod<void>('showDeadlineReminder', payload.toMap());
  }

  @override
  Future<void> synchronizeScheduledDeadlineReminders(
    List<ScheduledDeadlineReminder> reminders,
  ) {
    return _channel.invokeMethod<void>(
      'synchronizeScheduledDeadlineReminders',
      reminders.map((reminder) => reminder.toMap()).toList(growable: false),
    );
  }

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {
    _expandRequestHandler = handler;
    final pendingExpansionAnchor = _pendingExpansionAnchor;
    if (handler == null || pendingExpansionAnchor == null) {
      return;
    }
    _pendingExpansionAnchor = null;
    handler(pendingExpansionAnchor);
  }

  @override
  void setCollapseRequestHandler(CollapseRequestHandler? handler) {
    _collapseRequestHandler = handler;
    if (handler == null || !_pendingCollapseRequest) {
      return;
    }
    _pendingCollapseRequest = false;
    handler();
  }

  @override
  Future<void> synchronizeCollapsedState() {
    return _channel.invokeMethod<void>('synchronizeCollapsedState');
  }

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    final value = await _channel.invokeMethod<String>(
      'preferredExpansionAnchor',
    );
    return WindowExpansionAnchor.fromWireValue(value);
  }

  @override
  Future<void> setExpanded(bool expanded, {bool animated = true}) {
    return _channel.invokeMethod<void>('setExpanded', <String, bool>{
      'expanded': expanded,
      'animated': animated,
    });
  }

  @override
  Future<void> setFloatingIconCount(int activeCount) {
    return _channel.invokeMethod<void>('setFloatingIconCount', activeCount);
  }

  @override
  Future<void> setPreferredLanguage(String? languageCode) {
    return _channel.invokeMethod<void>('setPreferredLanguage', languageCode);
  }

  @override
  Future<void> setPreferredTheme(String themePreference) {
    return _channel.invokeMethod<void>('setPreferredTheme', themePreference);
  }

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) {
    return _channel.invokeMethod<void>('setAlwaysOnTop', alwaysOnTop);
  }

  Future<void> _handleNativeMethod(MethodCall call) async {
    switch (call.method) {
      case 'requestExpand':
        final expansionAnchor = WindowExpansionAnchor.fromWireValue(
          call.arguments,
        );
        final handler = _expandRequestHandler;
        if (handler == null) {
          _pendingExpansionAnchor = expansionAnchor;
        } else {
          handler(expansionAnchor);
        }
        return;
      case 'requestCollapse':
        final handler = _collapseRequestHandler;
        if (handler == null) {
          _pendingCollapseRequest = true;
        } else {
          handler();
        }
        return;
      case 'deadlineReminderAction':
        final arguments = call.arguments;
        if (arguments is! Map<Object?, Object?>) {
          throw const FormatException(
            'Deadline reminder action must be a map.',
          );
        }
        final todoId = arguments['todoId'];
        final kindName = arguments['action'];
        if (todoId is! String || kindName is! String) {
          throw const FormatException(
            'Deadline reminder action is missing required fields.',
          );
        }
        final kind = DeadlineReminderActionKind.values.firstWhere(
          (value) => value.name == kindName,
          orElse: () => throw FormatException(
            'Unknown deadline reminder action: $kindName',
          ),
        );
        _deadlineReminderActionHandler?.call(
          DeadlineReminderAction(kind: kind, todoId: todoId),
        );
        return;
      case 'deadlineReminderDelivered':
        final arguments = call.arguments;
        if (arguments is! Map<Object?, Object?>) {
          throw const FormatException(
            'Deadline reminder delivery must be a map.',
          );
        }
        final notificationId = arguments['notificationId'];
        final todoId = arguments['todoId'];
        final kindName = arguments['deliveryKind'];
        if (notificationId is! String ||
            todoId is! String ||
            kindName is! String) {
          throw const FormatException(
            'Deadline reminder delivery is missing required fields.',
          );
        }
        final kind = DeadlineReminderDeliveryKind.values.firstWhere(
          (value) => value.name == kindName,
          orElse: () => throw FormatException(
            'Unknown deadline reminder delivery kind: $kindName',
          ),
        );
        _deadlineReminderDeliveryHandler?.call(
          DeadlineReminderDelivery(
            notificationId: notificationId,
            todoId: todoId,
            kind: kind,
          ),
        );
        return;
      default:
        throw MissingPluginException(
          'Unsupported native method: ${call.method}',
        );
    }
  }
}
