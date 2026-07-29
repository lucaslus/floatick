import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_markdown_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats a title and Markdown content for agent handoff', () {
    final item = TodoItem(
      id: 'todo-1',
      title: '  Prepare agent handoff  ',
      content: '\n\n- Review context\n- Implement change\n\n',
      createdAt: DateTime.utc(2026, 7, 29),
    );

    expect(
      TodoMarkdownFormatter.format(item),
      '# Prepare agent handoff\n\n'
      '- Review context\n'
      '- Implement change',
    );
  });

  test('formats a title-only todo without an empty content section', () {
    final item = TodoItem(
      id: 'todo-2',
      title: 'Capture the idea',
      createdAt: DateTime.utc(2026, 7, 29),
    );

    expect(TodoMarkdownFormatter.format(item), '# Capture the idea');
  });

  test('normalizes title line breaks and preserves content indentation', () {
    final item = TodoItem(
      id: 'todo-3',
      title: 'Review\n  generated plan',
      content: '\r\n    indented code\r\n\r\n',
      createdAt: DateTime.utc(2026, 7, 29),
    );

    expect(
      TodoMarkdownFormatter.format(item),
      '# Review generated plan\n\n    indented code',
    );
  });
}
