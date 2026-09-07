import 'todo_tag.dart';

class TagWorkspace {
  TagWorkspace({
    required Iterable<TodoTag> tags,
    required Map<String, Iterable<String>> assignments,
  }) : tags = List<TodoTag>.unmodifiable(tags),
       assignments = Map<String, List<String>>.unmodifiable(
         assignments.map(
           (todoId, tagIds) =>
               MapEntry(todoId, List<String>.unmodifiable(tagIds.toSet())),
         ),
       );

  factory TagWorkspace.empty() {
    return TagWorkspace(
      tags: const <TodoTag>[],
      assignments: const <String, List<String>>{},
    );
  }

  final List<TodoTag> tags;
  final Map<String, List<String>> assignments;

  List<String> tagIdsForTodo(String todoId) {
    return assignments[todoId] ?? const <String>[];
  }

  factory TagWorkspace.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != 1) {
      throw const FormatException(
        'Tag workspace field "version" must equal 1.',
      );
    }

    final rawTags = json['tags'];
    if (rawTags is! List<dynamic>) {
      throw const FormatException(
        'Tag workspace field "tags" must be a JSON array.',
      );
    }
    final tags = rawTags
        .map((entry) {
          if (entry is! Map<dynamic, dynamic>) {
            throw const FormatException('Each tag must be a JSON object.');
          }
          return TodoTag.fromJson(Map<String, dynamic>.from(entry));
        })
        .toList(growable: false);
    if (tags.map((tag) => tag.id).toSet().length != tags.length) {
      throw const FormatException('Tag ids must be unique.');
    }
    if (tags.map((tag) => tag.name.toLowerCase()).toSet().length !=
        tags.length) {
      throw const FormatException(
        'Tag names must be unique regardless of letter case.',
      );
    }
    final knownTagIds = tags.map((tag) => tag.id).toSet();

    final rawAssignments = json['assignments'];
    if (rawAssignments is! Map<dynamic, dynamic>) {
      throw const FormatException(
        'Tag workspace field "assignments" must be a JSON object.',
      );
    }
    final assignments = <String, List<String>>{};
    for (final entry in rawAssignments.entries) {
      if (entry.key is! String ||
          (entry.key as String).trim().isEmpty ||
          entry.value is! List<dynamic>) {
        throw const FormatException(
          'Each tag assignment must map a todo id to a JSON array.',
        );
      }
      final tagIds = <String>[];
      for (final tagId in entry.value as List<dynamic>) {
        if (tagId is! String || tagId.trim().isEmpty) {
          throw const FormatException(
            'Assigned tag ids must be non-empty strings.',
          );
        }
        tagIds.add(tagId);
      }
      if (tagIds.any((tagId) => !knownTagIds.contains(tagId))) {
        throw const FormatException(
          'Tag assignments must reference existing tag ids.',
        );
      }
      assignments[entry.key as String] = tagIds;
    }

    return TagWorkspace(tags: tags, assignments: assignments);
  }

  Map<String, dynamic> toJson() {
    final sortedAssignments = assignments.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return <String, dynamic>{
      'version': 1,
      'tags': tags.map((tag) => tag.toJson()).toList(growable: false),
      'assignments': <String, dynamic>{
        for (final entry in sortedAssignments) entry.key: entry.value,
      },
    };
  }
}
