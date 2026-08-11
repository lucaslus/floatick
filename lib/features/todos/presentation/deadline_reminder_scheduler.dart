import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/platform/window_bridge.dart';
import '../domain/todo_item.dart';
import 'todo_view_model.dart';

typedef DeadlineReminderClock = DateTime Function();
typedef OpenTodoFromReminder = void Function(String todoId);

enum _ReminderEventKind { snoozed, deadline, advance }

class DeadlineReminderScheduler with WidgetsBindingObserver {
  DeadlineReminderScheduler({
    required TodoViewModel todoViewModel,
    required DeadlineReminderBridge bridge,
    required OpenTodoFromReminder onOpenTodo,
    DeadlineReminderClock? clock,
  }) : this._(todoViewModel, bridge, onOpenTodo, clock ?? DateTime.now);

  DeadlineReminderScheduler._(
    this._todoViewModel,
    this._bridge,
    this._onOpenTodo,
    this._clock,
  ) {
    WidgetsBinding.instance.addObserver(this);
    _todoViewModel.addListener(_scheduleNext);
    _bridge.setDeadlineReminderActionHandler(_handleAction);
    _bridge.setDeadlineReminderDeliveryHandler(_handleDelivery);
    _scheduleNext();
  }

  static const Duration _maximumTimerDuration = Duration(days: 20);

  final TodoViewModel _todoViewModel;
  final DeadlineReminderBridge _bridge;
  final OpenTodoFromReminder _onOpenTodo;
  final DeadlineReminderClock _clock;

  Timer? _timer;
  bool _isDisposed = false;
  bool _isDispatching = false;
  DateTime? _retryAfter;

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _todoViewModel.removeListener(_scheduleNext);
    _bridge.setDeadlineReminderActionHandler(null);
    _bridge.setDeadlineReminderDeliveryHandler(null);
  }

  void refresh() {
    _scheduleNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  void _scheduleNext() {
    if (_isDisposed || _isDispatching) {
      return;
    }
    _timer?.cancel();
    final now = _clock().toUtc();
    final events = _pendingEvents(now);
    _synchronizeNativeSchedule(events, now);
    final retryAfter = _retryAfter;
    if (retryAfter != null && now.isBefore(retryAfter)) {
      _timer = Timer(retryAfter.difference(now), _scheduleNext);
      return;
    }
    if (events.isEmpty) {
      return;
    }
    final event = events.first;
    final delay = event.at.difference(now);
    if (delay <= Duration.zero) {
      scheduleMicrotask(() => unawaited(_dispatch(event)));
      return;
    }
    final timerDelay = delay > _maximumTimerDuration
        ? _maximumTimerDuration
        : delay;
    _timer = Timer(timerDelay, _scheduleNext);
  }

  List<_ReminderEvent> _pendingEvents(DateTime now) {
    final events = <_ReminderEvent>[];
    for (final item in _todoViewModel.items) {
      if (item.isCompleted || item.isArchived || item.dueAt == null) {
        continue;
      }
      if (item.snoozedUntil case final snoozedUntil?) {
        events.add(
          _ReminderEvent(
            item: item,
            kind: _ReminderEventKind.snoozed,
            at: snoozedUntil,
          ),
        );
      }
      final dueAt = item.dueAt!;
      if (item.notifyAtDeadline && item.deadlineNotifiedAt == null) {
        events.add(
          _ReminderEvent(
            item: item,
            kind: _ReminderEventKind.deadline,
            at: dueAt,
          ),
        );
      }
      final reminderAt = item.reminderAt;
      final reminderIsStillRelevant =
          reminderAt != null &&
          item.reminderNotifiedAt == null &&
          (!item.notifyAtDeadline ||
              reminderAt.isAfter(dueAt) ||
              now.isBefore(dueAt));
      if (reminderIsStillRelevant) {
        events.add(
          _ReminderEvent(
            item: item,
            kind: _ReminderEventKind.advance,
            at: reminderAt,
          ),
        );
      }
    }
    events.sort((left, right) {
      final timeComparison = left.at.compareTo(right.at);
      if (timeComparison != 0) {
        return timeComparison;
      }
      return left.kind.index.compareTo(right.kind.index);
    });
    return events;
  }

  void _synchronizeNativeSchedule(List<_ReminderEvent> events, DateTime now) {
    final reminders = events
        .map(
          (event) => ScheduledDeadlineReminder(
            notificationId: event.notificationId,
            triggerAt: event.at,
            deliveryKind: event.deliveryKind,
            payload: _payloadFor(event, now),
          ),
        )
        .toList(growable: false);
    unawaited(
      _bridge.synchronizeScheduledDeadlineReminders(reminders).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Floatick could not synchronize native deadline reminders: '
          '$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }),
    );
  }

  DeadlineReminderPayload _payloadFor(_ReminderEvent event, DateTime now) {
    final dueAt = event.item.dueAt!;
    final tags = _todoViewModel.tagsForTodo(event.item.id);
    return DeadlineReminderPayload(
      notificationId: event.notificationId,
      todoId: event.item.id,
      title: event.item.title,
      dueLabel: _formatDueLabel(dueAt.toLocal()),
      isOverdue: now.isAfter(dueAt),
      isAdvanceReminder:
          event.kind == _ReminderEventKind.advance ||
          (event.kind == _ReminderEventKind.snoozed && now.isBefore(dueAt)),
      tagLabel: tags.isEmpty ? null : tags.first.name,
    );
  }

  Future<void> _dispatch(_ReminderEvent event) async {
    if (_isDisposed || _isDispatching) {
      return;
    }
    final currentItem = _todoViewModel.itemById(event.item.id);
    if (currentItem == null ||
        currentItem.isCompleted ||
        currentItem.isArchived) {
      _scheduleNext();
      return;
    }
    _isDispatching = true;
    try {
      final dueAt = currentItem.dueAt;
      if (dueAt == null) {
        return;
      }
      final now = _clock().toUtc();
      final currentEvent = _ReminderEvent(
        item: currentItem,
        kind: event.kind,
        at: event.at,
      );
      final isStillPending = _pendingEvents(
        now,
      ).any((candidate) => candidate.notificationId == event.notificationId);
      if (!isStillPending) {
        return;
      }
      await _bridge.showDeadlineReminder(_payloadFor(currentEvent, now));
      _retryAfter = null;
      switch (event.kind) {
        case _ReminderEventKind.snoozed:
          await _todoViewModel.clearSnoozedNotification(currentItem.id);
          break;
        case _ReminderEventKind.deadline:
          await _todoViewModel.markDeadlineNotificationDelivered(
            currentItem.id,
          );
          if (currentItem.reminderAt != null &&
              !currentItem.reminderAt!.isAfter(dueAt) &&
              currentItem.reminderNotifiedAt == null) {
            await _todoViewModel.markReminderNotificationDelivered(
              currentItem.id,
            );
          }
          break;
        case _ReminderEventKind.advance:
          await _todoViewModel.markReminderNotificationDelivered(
            currentItem.id,
          );
          break;
      }
    } on Object catch (error, stackTrace) {
      _retryAfter = _clock().toUtc().add(const Duration(minutes: 1));
      debugPrint('Floatick could not show a deadline reminder: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isDispatching = false;
      _scheduleNext();
    }
  }

  void _handleAction(DeadlineReminderAction action) {
    switch (action.kind) {
      case DeadlineReminderActionKind.open:
        _onOpenTodo(action.todoId);
        break;
      case DeadlineReminderActionKind.dismiss:
        break;
    }
  }

  void _handleDelivery(DeadlineReminderDelivery delivery) {
    unawaited(
      _recordNativeDelivery(delivery).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Floatick could not persist a native deadline reminder: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }),
    );
  }

  Future<void> _recordNativeDelivery(DeadlineReminderDelivery delivery) async {
    if (_isDisposed) {
      return;
    }
    final item = _todoViewModel.itemById(delivery.todoId);
    if (item == null || item.isCompleted || item.isArchived) {
      return;
    }
    final now = _clock().toUtc();
    final isStillPending = _pendingEvents(
      now,
    ).any((event) => event.notificationId == delivery.notificationId);
    if (!isStillPending) {
      return;
    }
    switch (delivery.kind) {
      case DeadlineReminderDeliveryKind.snoozed:
        if (item.snoozedUntil != null) {
          await _todoViewModel.clearSnoozedNotification(item.id);
        }
        break;
      case DeadlineReminderDeliveryKind.deadline:
        if (item.deadlineNotifiedAt == null) {
          await _todoViewModel.markDeadlineNotificationDelivered(item.id);
        }
        final dueAt = item.dueAt;
        if (dueAt != null &&
            item.reminderAt != null &&
            !item.reminderAt!.isAfter(dueAt) &&
            item.reminderNotifiedAt == null) {
          await _todoViewModel.markReminderNotificationDelivered(item.id);
        }
        break;
      case DeadlineReminderDeliveryKind.advance:
        if (item.reminderNotifiedAt == null) {
          await _todoViewModel.markReminderNotificationDelivered(item.id);
        }
        break;
    }
  }
}

String _formatDueLabel(DateTime dueAt) {
  final hour = dueAt.hour.toString().padLeft(2, '0');
  final minute = dueAt.minute.toString().padLeft(2, '0');
  return '${dueAt.month}/${dueAt.day} · $hour:$minute';
}

class _ReminderEvent {
  const _ReminderEvent({
    required this.item,
    required this.kind,
    required this.at,
  });

  final TodoItem item;
  final _ReminderEventKind kind;
  final DateTime at;

  String get notificationId =>
      '${item.id}:${kind.name}:${at.toUtc().microsecondsSinceEpoch}';

  DeadlineReminderDeliveryKind get deliveryKind => switch (kind) {
    _ReminderEventKind.snoozed => DeadlineReminderDeliveryKind.snoozed,
    _ReminderEventKind.deadline => DeadlineReminderDeliveryKind.deadline,
    _ReminderEventKind.advance => DeadlineReminderDeliveryKind.advance,
  };
}
