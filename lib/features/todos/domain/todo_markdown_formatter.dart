import 'todo_item.dart';

abstract final class TodoMarkdownFormatter {
  static String format(TodoItem item) {
    final title = item.title.trim().replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ');
    final content = _trimBlankEdgeLines(
      item.content.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
    );
    if (content.isEmpty) {
      return '# $title';
    }
    return '# $title\n\n$content';
  }

  static String _trimBlankEdgeLines(String value) {
    final lines = value.split('\n');
    var start = 0;
    var end = lines.length;
    while (start < end && lines[start].trim().isEmpty) {
      start += 1;
    }
    while (end > start && lines[end - 1].trim().isEmpty) {
      end -= 1;
    }
    return lines.sublist(start, end).join('\n');
  }
}
