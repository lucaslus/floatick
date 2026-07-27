import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../todos/domain/todo_item.dart';
import '../../../todos/domain/todo_tag.dart';
import '../../../todos/presentation/widgets/floatick_tag_chip.dart';
import '../../../todos/presentation/widgets/todo_markdown.dart';

class StickyBoardTodoDetails extends StatelessWidget {
  const StickyBoardTodoDetails({
    required this.item,
    required this.tags,
    required this.onBack,
    required this.onEdit,
    super.key,
  });

  final TodoItem item;
  final List<TodoTag> tags;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      key: const Key('sticky-board-todo-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
          child: Row(
            children: <Widget>[
              IconButton(
                key: const Key('sticky-board-details-back'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  context.l10n.todoDetailsDrawerTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                key: const Key('sticky-board-details-edit'),
                tooltip: context.l10n.editTooltip,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: onSurface.withValues(alpha: 0.08)),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 2),
          child: Text(
            item.title,
            key: const Key('sticky-board-details-title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
            child: Wrap(
              key: const Key('sticky-board-details-tags'),
              spacing: 6,
              runSpacing: 5,
              children: <Widget>[
                for (final tag in tags)
                  FloatickTagChip(
                    key: ValueKey<String>('sticky-board-details-tag-${tag.id}'),
                    tag: tag,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: item.content.trim().isEmpty
              ? _EmptyStickyBoardTodoContent(onSurface: onSurface)
              : TodoMarkdownContent(
                  key: const Key('sticky-board-details-markdown'),
                  content: item.content,
                ),
        ),
      ],
    );
  }
}

class _EmptyStickyBoardTodoContent extends StatelessWidget {
  const _EmptyStickyBoardTodoContent({required this.onSurface});

  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.notes_rounded,
              size: 28,
              color: onSurface.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 9),
            Text(
              context.l10n.noTodoContentTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.noTodoContentMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
