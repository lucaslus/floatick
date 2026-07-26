class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.content = '',
    this.completedAt,
    this.archivedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;

  bool get isCompleted => completedAt != null;
  bool get isArchived => archivedAt != null;

  TodoItem withTitle(String value) {
    return TodoItem(
      id: id,
      title: value,
      content: content,
      createdAt: createdAt,
      completedAt: completedAt,
      archivedAt: archivedAt,
    );
  }

  TodoItem withDetails({required String title, required String content}) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      completedAt: completedAt,
      archivedAt: archivedAt,
    );
  }

  TodoItem withCompletedAt(DateTime? value) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      completedAt: value,
      archivedAt: archivedAt,
    );
  }

  TodoItem withArchivedAt(DateTime? value) {
    return TodoItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      completedAt: completedAt,
      archivedAt: value,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      content: _optionalString(json, 'content'),
      createdAt: _requiredDate(json, 'createdAt'),
      completedAt: _optionalDate(json, 'completedAt'),
      archivedAt: _optionalDate(json, 'archivedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (content.isNotEmpty) 'content': content,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (completedAt != null)
        'completedAt': completedAt!.toUtc().toIso8601String(),
      if (archivedAt != null)
        'archivedAt': archivedAt!.toUtc().toIso8601String(),
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

  @override
  bool operator ==(Object other) {
    return other is TodoItem &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.archivedAt == archivedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content, createdAt, completedAt, archivedAt);
  }
}
