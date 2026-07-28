import 'package:flutter/material.dart';

import '../../../../core/ui/floatick_hover_motion.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/todo_item.dart';
import '../../domain/todo_tag.dart';
import 'floatick_tag_chip.dart';
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
    this.onToggleTag,
    this.onOpenTagManagement,
    this.onOpenTagAssignment,
    this.onRemoveFromStickyBoard,
    this.onDeletePermanently,
    this.showArchiveAction = true,
    this.compact = false,
    super.key,
  }) : assert(
         archivedScope ||
             onOpenTagAssignment != null ||
             (onToggleTag != null && onOpenTagManagement != null),
       ),
       assert(!archivedScope || onEdit == null),
       assert(archivedScope || onEdit != null),
       assert(archivedScope || onDeletePermanently == null),
       assert(!archivedScope || onDeletePermanently != null);

  final TodoItem item;
  final bool archivedScope;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetails;
  final VoidCallback? onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final Future<bool> Function(String tagId)? onToggleTag;
  final VoidCallback? onOpenTagManagement;
  final VoidCallback? onOpenTagAssignment;
  final VoidCallback? onRemoveFromStickyBoard;
  final VoidCallback? onDeletePermanently;
  final bool showArchiveAction;
  final bool compact;

  @override
  State<TodoListRow> createState() => _TodoListRowState();
}

class _TodoListRowState extends State<TodoListRow> {
  final _rowFocusNode = FocusNode();

  bool _isHovered = false;
  bool _hasFocus = false;
  bool _isConfirmingDelete = false;

  @override
  void dispose() {
    _rowFocusNode.dispose();
    super.dispose();
  }

  void _requestPermanentDelete() {
    setState(() => _isConfirmingDelete = true);
    _rowFocusNode.requestFocus();
  }

  void _cancelPermanentDelete() {
    setState(() => _isConfirmingDelete = false);
  }

  void _confirmPermanentDelete() {
    setState(() => _isConfirmingDelete = false);
    widget.onDeletePermanently?.call();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final localizations = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showContextActions = _isHovered || _hasFocus || _isConfirmingDelete;
    final trailingActionCount = widget.archivedScope
        ? 3
        : 2 +
              (widget.showArchiveAction ? 1 : 0) +
              (widget.onRemoveFromStickyBoard == null ? 0 : 1);

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (!widget.archivedScope)
                      Tooltip(
                        message: item.isCompleted
                            ? localizations.markIncompleteTooltip
                            : localizations.markCompleteTooltip,
                        child: Semantics(
                          button: true,
                          checked: item.isCompleted,
                          child: FloatickHoverMotion(
                            child: GestureDetector(
                              key: ValueKey<String>(
                                'toggle-todo-${widget.item.id}',
                              ),
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
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
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
                          key: ValueKey<String>(
                            'archived-status-${widget.item.id}',
                          ),
                          size: 21,
                          color: onSurface.withValues(alpha: 0.28),
                        ),
                      ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: ValueKey<String>(
                            'todo-open-details-region-${widget.item.id}',
                          ),
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: widget.onOpenDetails,
                          child: SizedBox(
                            height: 30,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.title,
                                key: ValueKey<String>(
                                  'todo-title-${widget.item.id}',
                                ),
                                maxLines: 1,
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
                                  decorationColor: onSurface.withValues(
                                    alpha: 0.42,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    SizedBox(
                      width: trailingActionCount * 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          if (!widget.archivedScope)
                            _HoverAction(
                              visible: showContextActions,
                              tooltip: localizations.editTooltip,
                              onPressed: widget.onEdit!,
                              icon: Icons.edit_outlined,
                              key: ValueKey<String>(
                                'edit-todo-${widget.item.id}',
                              ),
                            ),
                          _ActionButton(
                            tooltip: localizations.viewTodoDetailsTooltip,
                            onPressed: widget.onOpenDetails,
                            icon: Icons.subject_rounded,
                            color: item.content.trim().isEmpty
                                ? onSurface.withValues(alpha: 0.42)
                                : Theme.of(context).colorScheme.primary,
                            key: ValueKey<String>(
                              'view-todo-${widget.item.id}',
                            ),
                          ),
                          if (widget.archivedScope && _isConfirmingDelete) ...[
                            _ActionButton(
                              key: ValueKey<String>(
                                'cancel-delete-todo-${widget.item.id}',
                              ),
                              tooltip: localizations.cancelDeleteTodoTooltip,
                              onPressed: _cancelPermanentDelete,
                              icon: Icons.close_rounded,
                            ),
                            _ActionButton(
                              key: ValueKey<String>(
                                'confirm-delete-todo-${widget.item.id}',
                              ),
                              tooltip: localizations.confirmDeleteTodoTooltip,
                              onPressed: _confirmPermanentDelete,
                              icon: Icons.delete_forever_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ] else if (widget.archivedScope) ...[
                            _ActionButton(
                              key: ValueKey<String>(
                                'restore-todo-${widget.item.id}',
                              ),
                              tooltip: localizations.restoreTooltip,
                              onPressed: widget.onRestore,
                              icon: Icons.unarchive_outlined,
                            ),
                            _HoverAction(
                              key: ValueKey<String>(
                                'delete-todo-${widget.item.id}',
                              ),
                              visible: showContextActions,
                              tooltip:
                                  localizations.deleteTodoPermanentlyTooltip,
                              onPressed: _requestPermanentDelete,
                              icon: Icons.delete_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ] else if (widget.showArchiveAction)
                            _ActionButton(
                              key: ValueKey<String>(
                                'archive-todo-${widget.item.id}',
                              ),
                              tooltip: localizations.archiveTooltip,
                              onPressed: widget.onArchive,
                              icon: Icons.archive_outlined,
                            ),
                          if (widget.onRemoveFromStickyBoard != null)
                            _HoverAction(
                              key: ValueKey<String>(
                                'remove-from-board-${widget.item.id}',
                              ),
                              visible: showContextActions,
                              tooltip:
                                  localizations.removeFromStickyBoardTooltip,
                              onPressed: widget.onRemoveFromStickyBoard!,
                              icon: Icons.remove_circle_outline_rounded,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.compact ? 3 : 5),
                Row(
                  key: ValueKey<String>('todo-metadata-row-${widget.item.id}'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: 36),
                    Expanded(
                      child: widget.archivedScope
                          ? _ReadOnlyTodoTags(
                              todoId: item.id,
                              tags: widget.tags,
                              assignedTagIds: widget.assignedTagIds,
                            )
                          : widget.onOpenTagAssignment == null
                          ? TagAssignmentMenu(
                              todoId: item.id,
                              tags: widget.tags,
                              assignedTagIds: widget.assignedTagIds,
                              onToggle: widget.onToggleTag!,
                              onManageTags: widget.onOpenTagManagement!,
                            )
                          : _ExternalTagAssignment(
                              todoId: item.id,
                              tags: widget.tags,
                              assignedTagIds: widget.assignedTagIds,
                              onPressed: widget.onOpenTagAssignment!,
                            ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _formatTime(
                        context,
                        widget.archivedScope
                            ? (item.archivedAt ?? item.createdAt)
                            : item.createdAt,
                      ),
                      key: ValueKey<String>('todo-time-${widget.item.id}'),
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.35),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExternalTagAssignment extends StatelessWidget {
  const _ExternalTagAssignment({
    required this.todoId,
    required this.tags,
    required this.assignedTagIds,
    required this.onPressed,
  });

  final String todoId;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final assignedIds = assignedTagIds.toSet();
    final assignedTags = tags
        .where((tag) => assignedIds.contains(tag.id))
        .toList(growable: false);

    return Wrap(
      spacing: 4,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final tag in assignedTags)
          FloatickTagChip(
            key: ValueKey<String>('todo-tag-$todoId-${tag.id}'),
            tag: tag,
            compact: true,
          ),
        SizedBox.square(
          dimension: 20,
          child: IconButton(
            key: ValueKey<String>('assign-tags-$todoId'),
            tooltip: context.l10n.assignTagsTooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            icon: Icon(
              assignedTags.isEmpty ? Icons.sell_outlined : Icons.sell_rounded,
              size: 13,
              color: assignedTags.isEmpty
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyTodoTags extends StatelessWidget {
  const _ReadOnlyTodoTags({
    required this.todoId,
    required this.tags,
    required this.assignedTagIds,
  });

  final String todoId;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;

  @override
  Widget build(BuildContext context) {
    final assignedIds = assignedTagIds.toSet();
    final assignedTags = tags
        .where((tag) => assignedIds.contains(tag.id))
        .toList(growable: false);
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: <Widget>[
        for (final tag in assignedTags)
          FloatickTagChip(
            key: ValueKey<String>('todo-tag-$todoId-${tag.id}'),
            tag: tag,
            compact: true,
          ),
      ],
    );
  }
}

class _HoverAction extends StatelessWidget {
  const _HoverAction({
    required this.visible,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.color,
    super.key,
  });

  final bool visible;
  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;

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
            icon: Icon(icon, size: 16, color: color),
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
