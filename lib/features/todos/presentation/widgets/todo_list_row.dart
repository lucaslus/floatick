import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/todo_item.dart';
import '../../domain/todo_tag.dart';
import 'tag_menus.dart';

class TodoListRow extends StatefulWidget {
  const TodoListRow({
    required this.item,
    required this.archivedScope,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.tags,
    required this.assignedTagIds,
    required this.onToggleTag,
    required this.onOpenTagManagement,
    this.onRemoveFromStickyBoard,
    this.compact = false,
    super.key,
  });

  final TodoItem item;
  final bool archivedScope;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final Future<void> Function(String tagId) onToggleTag;
  final VoidCallback onOpenTagManagement;
  final VoidCallback? onRemoveFromStickyBoard;
  final bool compact;

  @override
  State<TodoListRow> createState() => _TodoListRowState();
}

class _TodoListRowState extends State<TodoListRow> {
  final _rowFocusNode = FocusNode();

  bool _isHovered = false;
  bool _hasFocus = false;

  @override
  void dispose() {
    _rowFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final localizations = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showContextActions = _isHovered || _hasFocus;
    final trailingActionCount =
        3 + (widget.onRemoveFromStickyBoard == null ? 0 : 1);

    return Focus(
      focusNode: _rowFocusNode,
      onFocusChange: (hasFocus) {
        if (_hasFocus != hasFocus) {
          setState(() => _hasFocus = hasFocus);
        }
      },
      child: Semantics(
        container: true,
        label: item.title,
        value: item.isCompleted
            ? localizations.completedStatus
            : localizations.incompleteStatus,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: EdgeInsets.fromLTRB(
              widget.compact ? 4 : 7,
              widget.compact ? 6 : 8,
              5,
              widget.compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.055)
                        : Colors.black.withValues(alpha: 0.035))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: <Widget>[
                if (!widget.archivedScope)
                  Tooltip(
                    message: item.isCompleted
                        ? localizations.markIncompleteTooltip
                        : localizations.markCompleteTooltip,
                    child: Semantics(
                      button: true,
                      checked: item.isCompleted,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onToggle,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 160),
                              width: 21,
                              height: 21,
                              decoration: BoxDecoration(
                                color: item.isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: item.isCompleted
                                      ? Theme.of(context).colorScheme.primary
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
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 21,
                      color: onSurface.withValues(alpha: 0.28),
                    ),
                  ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        maxLines: widget.compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withValues(
                            alpha: item.isCompleted ? 0.45 : 0.91,
                          ),
                          fontSize: widget.compact ? 12.5 : 13.5,
                          height: 1.3,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: onSurface.withValues(alpha: 0.42),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: TagAssignmentMenu(
                              todoId: item.id,
                              tags: widget.tags,
                              assignedTagIds: widget.assignedTagIds,
                              onToggle: widget.onToggleTag,
                              onManageTags: widget.onOpenTagManagement,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _formatTime(
                                context,
                                widget.archivedScope
                                    ? (item.archivedAt ?? item.createdAt)
                                    : item.createdAt,
                              ),
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.35),
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 3),
                SizedBox(
                  width: trailingActionCount * 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      _HoverAction(
                        visible: showContextActions,
                        tooltip: localizations.editTooltip,
                        onPressed: widget.onEdit,
                        icon: Icons.edit_outlined,
                        key: ValueKey<String>('edit-todo-${widget.item.id}'),
                      ),
                      _ActionButton(
                        tooltip: localizations.viewTodoDetailsTooltip,
                        onPressed: widget.onOpenDetails,
                        icon: Icons.subject_rounded,
                        color: item.content.trim().isEmpty
                            ? onSurface.withValues(alpha: 0.42)
                            : Theme.of(context).colorScheme.primary,
                        key: ValueKey<String>('view-todo-${widget.item.id}'),
                      ),
                      _ActionButton(
                        tooltip: widget.archivedScope
                            ? localizations.restoreTooltip
                            : localizations.archiveTooltip,
                        onPressed: widget.archivedScope
                            ? widget.onRestore
                            : widget.onArchive,
                        icon: widget.archivedScope
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                      ),
                      if (widget.onRemoveFromStickyBoard != null)
                        _HoverAction(
                          visible: showContextActions,
                          tooltip: localizations.removeFromStickyBoardTooltip,
                          onPressed: widget.onRemoveFromStickyBoard!,
                          icon: Icons.remove_circle_outline_rounded,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverAction extends StatelessWidget {
  const _HoverAction({
    required this.visible,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    super.key,
  });

  final bool visible;
  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: 30,
      child: AnimatedOpacity(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 140),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 16),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.color,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 30,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

String _formatTime(BuildContext context, DateTime date) {
  final local = date.toLocal();
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
