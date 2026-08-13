class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.content = '',
    this.startedAt,
    this.completedAt,
    this.archivedAt,
    this.dueAt,
    this.reminderAt,
    this.notifyAtDeadline = true,
    this.deadlineNotifiedAt,
    this.reminderNotifiedAt,
    this.snoozedUntil,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final DateTime? dueAt;
  final DateTime? reminderAt;
  final bool notifyAtDeadline;
  final DateTime? deadlineNotifiedAt;
  final DateTime? reminderNotifiedAt;
  final DateTime? snoozedUntil;

  bool get isDoing => startedAt != null && !isCompleted && !isArchived;
  bool get isCompleted => completedAt != null;
  bool get isArchived => archivedAt != null;

  TodoItem withTitle(String value) {
    return TodoItem(
      id: id,
      title: value,
      content: content,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      archivedAt: archivedAt,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notifyAtDeadline: notifyAtDeadline,
      deadlineNotifiedAt: deadlineNotifiedAt,
      reminderNotifiedAt: reminderNotifiedAt,
      snoozedUntil: snoozedUntil,
    );
  }

  TodoItem withDetails({required String title, required String content}) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      archivedAt: archivedAt,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notifyAtDeadline: notifyAtDeadline,
      deadlineNotifiedAt: deadlineNotifiedAt,
      reminderNotifiedAt: reminderNotifiedAt,
      snoozedUntil: snoozedUntil,
    );
  }

  TodoItem withStartedAt(DateTime? value) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      startedAt: value,
      completedAt: completedAt,
      archivedAt: archivedAt,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notifyAtDeadline: notifyAtDeadline,
      deadlineNotifiedAt: deadlineNotifiedAt,
      reminderNotifiedAt: reminderNotifiedAt,
      snoozedUntil: snoozedUntil,
    );
  }

  TodoItem withCompletedAt(DateTime? value) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: value,
      archivedAt: archivedAt,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notifyAtDeadline: notifyAtDeadline,
      deadlineNotifiedAt: deadlineNotifiedAt,
      reminderNotifiedAt: reminderNotifiedAt,
      snoozedUntil: snoozedUntil,
    );
  }

  TodoItem withArchivedAt(DateTime? value) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      archivedAt: value,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notifyAtDeadline: notifyAtDeadline,
      deadlineNotifiedAt: deadlineNotifiedAt,
      reminderNotifiedAt: reminderNotifiedAt,
      snoozedUntil: snoozedUntil,
    );
  }

  TodoItem withSchedule(TodoScheduleDraft schedule) {
    final normalized = schedule.normalized();
    final scheduleChanged =
        dueAt != normalized.dueAt ||
        reminderAt != normalized.reminderAt ||
        notifyAtDeadline != normalized.notifyAtDeadline;
    if (!scheduleChanged) {
      return this;
    }
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      archivedAt: archivedAt,
      dueAt: normalized.dueAt,
      reminderAt: normalized.reminderAt,
      notifyAtDeadline: normalized.notifyAtDeadline,
    );
  }

  TodoItem withNotificationDelivery({
    DateTime? deadlineDeliveredAt,
    DateTime? reminderDeliveredAt,
  }) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      archivedAt: archivedAt,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notifyAtDeadline: notifyAtDeadline,
      deadlineNotifiedAt: deadlineDeliveredAt ?? deadlineNotifiedAt,
      reminderNotifiedAt: reminderDeliveredAt ?? reminderNotifiedAt,
      snoozedUntil: snoozedUntil,
    );
  }

  TodoItem withSnoozedUntil(DateTime? value) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      archivedAt: archivedAt,
      dueAt: dueAt,
      reminderAt: reminderAt,
      notifyAtDeadline: notifyAtDeadline,
      deadlineNotifiedAt: deadlineNotifiedAt,
      reminderNotifiedAt: reminderNotifiedAt,
      snoozedUntil: value,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      content: _optionalString(json, 'content'),
      createdAt: _requiredDate(json, 'createdAt'),
      startedAt: _optionalDate(json, 'startedAt'),
      completedAt: _optionalDate(json, 'completedAt'),
      archivedAt: _optionalDate(json, 'archivedAt'),
      dueAt: _optionalDate(json, 'dueAt'),
      reminderAt: _optionalDate(json, 'reminderAt'),
      notifyAtDeadline: _optionalBool(json, 'notifyAtDeadline') ?? true,
      deadlineNotifiedAt: _optionalDate(json, 'deadlineNotifiedAt'),
      reminderNotifiedAt: _optionalDate(json, 'reminderNotifiedAt'),
      snoozedUntil: _optionalDate(json, 'snoozedUntil'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (content.isNotEmpty) 'content': content,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (startedAt != null) 'startedAt': startedAt!.toUtc().toIso8601String(),
      if (completedAt != null)
        'completedAt': completedAt!.toUtc().toIso8601String(),
      if (archivedAt != null)
        'archivedAt': archivedAt!.toUtc().toIso8601String(),
      if (dueAt != null) 'dueAt': dueAt!.toUtc().toIso8601String(),
      if (reminderAt != null)
        'reminderAt': reminderAt!.toUtc().toIso8601String(),
      if (!notifyAtDeadline) 'notifyAtDeadline': false,
      if (deadlineNotifiedAt != null)
        'deadlineNotifiedAt': deadlineNotifiedAt!.toUtc().toIso8601String(),
      if (reminderNotifiedAt != null)
        'reminderNotifiedAt': reminderNotifiedAt!.toUtc().toIso8601String(),
      if (snoozedUntil != null)
        'snoozedUntil': snoozedUntil!.toUtc().toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Todo field "$key" must be a non-empty string.');
    }
    return value;
  }

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Todo field "$key" must be an ISO-8601 string.');
    }
    return DateTime.parse(value);
  }

  static String _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return '';
    }
    if (value is! String) {
      throw FormatException('Todo field "$key" must be a string.');
    }
    return value;
  }

  static DateTime? _optionalDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Todo field "$key" must be an ISO-8601 string.');
    }
    return DateTime.parse(value);
  }

  static bool? _optionalBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! bool) {
      throw FormatException('Todo field "$key" must be a boolean.');
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    return other is TodoItem &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.archivedAt == archivedAt &&
        other.dueAt == dueAt &&
        other.reminderAt == reminderAt &&
        other.notifyAtDeadline == notifyAtDeadline &&
        other.deadlineNotifiedAt == deadlineNotifiedAt &&
        other.reminderNotifiedAt == reminderNotifiedAt &&
        other.snoozedUntil == snoozedUntil;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      createdAt,
      startedAt,
      completedAt,
      archivedAt,
      dueAt,
      reminderAt,
      notifyAtDeadline,
      deadlineNotifiedAt,
      reminderNotifiedAt,
      snoozedUntil,
    );
  }
}

class TodoScheduleDraft {
  const TodoScheduleDraft({
    this.dueAt,
    this.reminderAt,
    this.notifyAtDeadline = true,
  });

  final DateTime? dueAt;
  final DateTime? reminderAt;
  final bool notifyAtDeadline;

  bool get hasDeadline => dueAt != null;

  TodoScheduleDraft normalized() {
    final normalizedDueAt = dueAt?.toUtc();
    if (normalizedDueAt == null) {
      return const TodoScheduleDraft();
    }
    return TodoScheduleDraft(
      dueAt: normalizedDueAt,
      reminderAt: reminderAt?.toUtc(),
      notifyAtDeadline: notifyAtDeadline,
    );
  }

  factory TodoScheduleDraft.fromItem(TodoItem? item) {
    return TodoScheduleDraft(
      dueAt: item?.dueAt,
      reminderAt: item?.reminderAt,
      notifyAtDeadline: item?.notifyAtDeadline ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TodoScheduleDraft &&
        other.dueAt == dueAt &&
        other.reminderAt == reminderAt &&
        other.notifyAtDeadline == notifyAtDeadline;
  }

  @override
  int get hashCode => Object.hash(dueAt, reminderAt, notifyAtDeadline);
}
