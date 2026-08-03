import 'package:flutter/foundation.dart';

class NoteItem {
  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    Iterable<String> tagIds = const <String>[],
    this.pinnedAt,
    this.archivedAt,
  }) : tagIds = List<String>.unmodifiable(tagIds.toSet());

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tagIds;
  final DateTime? pinnedAt;
  final DateTime? archivedAt;

  bool get isPinned => pinnedAt != null;
  bool get isArchived => archivedAt != null;

  NoteItem withDetails({
    required String title,
    required String content,
    required DateTime updatedAt,
    required Iterable<String> tagIds,
  }) {
    return NoteItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tagIds: tagIds,
      pinnedAt: pinnedAt,
      archivedAt: archivedAt,
    );
  }

  NoteItem withPinnedAt(DateTime? value) {
    return NoteItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tagIds: tagIds,
      pinnedAt: value,
      archivedAt: archivedAt,
    );
  }

  NoteItem withArchivedAt(DateTime? value, {required DateTime updatedAt}) {
    return NoteItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tagIds: tagIds,
      pinnedAt: value == null ? pinnedAt : null,
      archivedAt: value,
    );
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    final createdAt = _requiredDate(json, 'createdAt');
    return NoteItem(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      content: _optionalString(json, 'content'),
      createdAt: createdAt,
      updatedAt: _optionalDate(json, 'updatedAt') ?? createdAt,
      tagIds: _optionalStringList(json, 'tagIds'),
      pinnedAt: _optionalDate(json, 'pinnedAt'),
      archivedAt: _optionalDate(json, 'archivedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (content.isNotEmpty) 'content': content,
      if (tagIds.isNotEmpty) 'tagIds': tagIds,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      if (pinnedAt != null) 'pinnedAt': pinnedAt!.toUtc().toIso8601String(),
      if (archivedAt != null)
        'archivedAt': archivedAt!.toUtc().toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Note field "$key" must be a non-empty string.');
    }
    return value;
  }

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Note field "$key" must be an ISO-8601 string.');
    }
    return DateTime.parse(value);
  }

  static String _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return '';
    }
    if (value is! String) {
      throw FormatException('Note field "$key" must be a string.');
    }
    return value;
  }

  static DateTime? _optionalDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Note field "$key" must be an ISO-8601 string.');
    }
    return DateTime.parse(value);
  }

  static List<String> _optionalStringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      return const <String>[];
    }
    if (value is! List<dynamic>) {
      throw FormatException('Note field "$key" must be a string array.');
    }
    final values = <String>[];
    for (final entry in value) {
      if (entry is! String || entry.trim().isEmpty) {
        throw FormatException(
          'Note field "$key" must contain non-empty strings.',
        );
      }
      values.add(entry);
    }
    if (values.toSet().length != values.length) {
      throw FormatException('Note field "$key" must not contain duplicates.');
    }
    return values;
  }

  @override
  bool operator ==(Object other) {
    return other is NoteItem &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        listEquals(other.tagIds, tagIds) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.pinnedAt == pinnedAt &&
        other.archivedAt == archivedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      Object.hashAll(tagIds),
      createdAt,
      updatedAt,
      pinnedAt,
      archivedAt,
    );
  }
}
