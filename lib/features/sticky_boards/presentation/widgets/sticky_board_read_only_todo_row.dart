import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../todos/domain/todo_item.dart';

class StickyBoardReadOnlyTodoRow extends StatefulWidget {
  const StickyBoardReadOnlyTodoRow({
    required this.item,
    required this.onToggleCompletion,
    required this.onOpenDetails,
    super.key,
  });

  final TodoItem item;
  final VoidCallback onToggleCompletion;
  final VoidCallback onOpenDetails;

  @override
  State<StickyBoardReadOnlyTodoRow> createState() =>
      _StickyBoardReadOnlyTodoRowState();
}

class _StickyBoardReadOnlyTodoRowState
    extends State<StickyBoardReadOnlyTodoRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      label: item.title,
      value: item.isCompleted
          ? context.l10n.completedStatus
          : context.l10n.incompleteStatus,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.fromLTRB(4, 5, 8, 5),
          decoration: BoxDecoration(
            color: _isHovered
                ? (theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.055)
                      : Colors.black.withValues(alpha: 0.035))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Semantics(
                button: true,
                checked: item.isCompleted,
                label: item.title,
                value: item.isCompleted
                    ? context.l10n.completedStatus
                    : context.l10n.incompleteStatus,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    key: ValueKey<String>(
                      'sticky-board-completion-toggle-${item.id}',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onToggleCompletion,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        key: ValueKey<String>(
                          'sticky-board-completion-status-${item.id}',
                        ),
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          color: item.isCompleted
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: item.isCompleted
                                ? theme.colorScheme.primary
                                : onSurface.withValues(alpha: 0.28),
                            width: 1.4,
                          ),
                        ),
                        child: item.isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: GestureDetector(
                  key: ValueKey<String>(
                    'sticky-board-open-details-region-${item.id}',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: widget.onOpenDetails,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 29),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.title,
                        key: ValueKey<String>(
                          'sticky-board-todo-title-${item.id}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onSurface.withValues(
                            alpha: item.isCompleted ? 0.45 : 0.91,
                          ),
                          fontWeight: FontWeight.w500,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: onSurface.withValues(alpha: 0.42),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
