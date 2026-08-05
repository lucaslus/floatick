import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../todos/domain/todo_item.dart';
import '../../../todos/domain/todo_tag.dart';
import '../../../todos/presentation/todo_clipboard_controller.dart';
import '../../../todos/presentation/widgets/floatick_tag_chip.dart';
import '../../../todos/presentation/widgets/todo_copy_button.dart';
import '../../../../core/ui/floatick_markdown.dart';

class StickyBoardTodoDetails extends StatefulWidget {
  const StickyBoardTodoDetails({
    required this.item,
    required this.tags,
    required this.onBack,
    super.key,
  });

  final TodoItem item;
  final List<TodoTag> tags;
  final VoidCallback onBack;

  @override
  State<StickyBoardTodoDetails> createState() => _StickyBoardTodoDetailsState();
}

class _StickyBoardTodoDetailsState extends State<StickyBoardTodoDetails> {
  final _copyController = TodoClipboardController();

  @override
  void didUpdateWidget(covariant StickyBoardTodoDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.title != widget.item.title ||
        oldWidget.item.content != widget.item.content) {
      _copyController.reset();
    }
  }

  @override
  void dispose() {
    _copyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final item = widget.item;

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
                onPressed: widget.onBack,
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
              TodoCopyButton(
                key: const Key('sticky-board-details-copy'),
                item: item,
                controller: _copyController,
                dimension: 40,
                iconSize: 18,
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
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
            child: Wrap(
              key: const Key('sticky-board-details-tags'),
              spacing: 6,
              runSpacing: 5,
              children: <Widget>[
                for (final tag in widget.tags)
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
              : FloatickMarkdownContent(
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
