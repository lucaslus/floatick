import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/ui/floatick_hover_motion.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/todo_item.dart';
import '../../domain/todo_tag.dart';
import '../todo_clipboard_controller.dart';
import 'floatick_tag_chip.dart';
import 'tag_menus.dart';
import 'todo_actions_bottom_sheet.dart';
import 'todo_copy_button.dart';

class TodoListRow extends StatefulWidget {
  const TodoListRow({
    required this.item,
    required this.archivedScope,
    required this.onToggle,
    required this.onToggleDoing,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.tags,
    required this.assignedTagIds,
    this.onToggleTag,
    this.onOpenTagManagement,
    this.onOpenTagAssignment,
    this.onDeletePermanently,
    this.showArchiveAction = true,
    this.compact = false,
    this.hoverEnabled = true,
    super.key,
  }) : assert(
         archivedScope ||
             onOpenTagAssignment != null ||
             (onToggleTag != null && onOpenTagManagement != null),
       ),
       assert(archivedScope || onToggleDoing != null),
       assert(!archivedScope || onEdit == null),
       assert(archivedScope || onEdit != null),
       assert(archivedScope || onDeletePermanently == null),
       assert(!archivedScope || onDeletePermanently != null);

  final TodoItem item;
  final bool archivedScope;
  final VoidCallback onToggle;
  final VoidCallback? onToggleDoing;
  final VoidCallback onOpenDetails;
  final VoidCallback? onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final Future<bool> Function(String tagId)? onToggleTag;
  final VoidCallback? onOpenTagManagement;
  final VoidCallback? onOpenTagAssignment;
  final VoidCallback? onDeletePermanently;
  final bool showArchiveAction;
  final bool compact;
  final bool hoverEnabled;

  @override
  State<TodoListRow> createState() => _TodoListRowState();
}

class _TodoListRowState extends State<TodoListRow> {
  final _rowFocusNode = FocusNode();
  final _copyController = TodoClipboardController();

  bool _isHovered = false;
  bool _hasFocus = false;

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() => _isHovered = value);
  }

  @override
  void didUpdateWidget(covariant TodoListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hoverEnabled && !widget.hoverEnabled) {
      _isHovered = false;
    }
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.title != widget.item.title ||
        oldWidget.item.content != widget.item.content) {
      _copyController.reset();
    }
  }

  @override
  void dispose() {
    _rowFocusNode.dispose();
    _copyController.dispose();
    super.dispose();
  }

  void _openTagAssignment() {
    final externalHandler = widget.onOpenTagAssignment;
    if (externalHandler != null) {
      externalHandler();
      return;
    }
    unawaited(
      showTodoTagAssignmentSheet(
        context: context,
        todoId: widget.item.id,
        tags: widget.tags,
        assignedTagIds: widget.assignedTagIds,
        onToggle: widget.onToggleTag!,
        onManageTags: widget.onOpenTagManagement!,
      ),
    );
  }

  Future<void> _confirmPermanentDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.deleteTodoConfirmationTitle),
          content: Text(context.l10n.deleteTodoConfirmationMessage),
          actions: <Widget>[
            TextButton(
              key: ValueKey<String>('cancel-delete-todo-${widget.item.id}'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancelAction),
            ),
            TextButton(
              key: ValueKey<String>('confirm-delete-todo-${widget.item.id}'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                context.l10n.deleteTodoAction,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete == true && mounted) {
      widget.onDeletePermanently?.call();
    }
  }

  Future<void> _showActions() async {
    _rowFocusNode.requestFocus();
    final action = await showTodoActionsBottomSheet(
      context: context,
      todoId: widget.item.id,
      archivedScope: widget.archivedScope,
      showArchiveAction: widget.showArchiveAction,
    );
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case TodoActionsSheetAction.copy:
        await _copyController.copy(widget.item);
        return;
      case TodoActionsSheetAction.viewDetails:
        widget.onOpenDetails();
        return;
      case TodoActionsSheetAction.edit:
        widget.onEdit?.call();
        return;
      case TodoActionsSheetAction.assignTags:
        _openTagAssignment();
        return;
      case TodoActionsSheetAction.archive:
        widget.onArchive();
        return;
      case TodoActionsSheetAction.restore:
        widget.onRestore();
        return;
      case TodoActionsSheetAction.deletePermanently:
        await _confirmPermanentDelete();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showContextActions = (widget.hoverEnabled && _isHovered) || _hasFocus;
    final isDoing = item.isDoing;
    final rowColor = isDoing
        ? theme.colorScheme.primary.withValues(
            alpha: isDark ? (_isHovered ? 0.11 : 0.08) : 0.07,
          )
        : _isHovered
        ? (isDark
              ? Colors.white.withValues(alpha: 0.055)
              : Colors.black.withValues(alpha: 0.035))
        : Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (_) => unawaited(_showActions()),
      child: Focus(
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
              : isDoing
              ? localizations.doingStatus
              : localizations.incompleteStatus,
          child: MouseRegion(
            onEnter: widget.hoverEnabled ? (_) => _setHovered(true) : null,
            onExit: (_) => _setHovered(false),
            child: AnimatedContainer(
              key: ValueKey<String>('todo-row-surface-${widget.item.id}'),
              duration: reduceMotion || !widget.hoverEnabled
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
                color: rowColor,
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
                                    fontWeight: item.isCompleted
                                        ? FontWeight.w400
                                        : FontWeight.w500,
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
                        width: widget.archivedScope ? 60 : 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            if (!widget.archivedScope)
                              _HoverAction(
                                key: ValueKey<String>(
                                  'toggle-doing-todo-${widget.item.id}',
                                ),
                                visible:
                                    !item.isCompleted && showContextActions,
                                semanticLabel: isDoing
                                    ? localizations.stopDoingTooltip
                                    : localizations.startDoingTooltip,
                                onPressed: widget.onToggleDoing!,
                                icon: isDoing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                foregroundColor: isDoing
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            TodoCopyButton(
                              key: ValueKey<String>(
                                'copy-todo-${widget.item.id}',
                              ),
                              item: item,
                              controller: _copyController,
                              visible: showContextActions,
                            ),
                            _HoverAction(
                              key: ValueKey<String>(
                                'more-todo-${widget.item.id}',
                              ),
                              visible: showContextActions,
                              semanticLabel:
                                  localizations.moreTodoActionsTooltip,
                              tooltip: localizations.moreTodoActionsTooltip,
                              onPressed: () => unawaited(_showActions()),
                              icon: Icons.more_horiz_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.compact ? 3 : 5),
                  Row(
                    key: ValueKey<String>(
                      'todo-metadata-row-${widget.item.id}',
                    ),
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
                            : _ExternalTagAssignment(
                                todoId: item.id,
                                tags: widget.tags,
                                assignedTagIds: widget.assignedTagIds,
                                onPressed: _openTagAssignment,
                                showDoingStatus: isDoing,
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
                          color: onSurface.withValues(alpha: 0.45),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    required this.showDoingStatus,
  });

  final String todoId;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final VoidCallback onPressed;
  final bool showDoingStatus;

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
              assignedTags.isEmpty
                  ? Icons.local_offer_outlined
                  : Icons.local_offer_rounded,
              size: 12,
              color: assignedTags.isEmpty
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (showDoingStatus) _DoingStatusChip(todoId: todoId),
      ],
    );
  }
}

class _DoingStatusChip extends StatelessWidget {
  const _DoingStatusChip({required this.todoId});

  final String todoId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      key: ValueKey<String>('doing-status-$todoId'),
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.28 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.doingStatus,
            style: TextStyle(
              color: color,
              fontSize: 9.25,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
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
    required this.semanticLabel,
    required this.onPressed,
    required this.icon,
    this.foregroundColor,
    this.tooltip,
    super.key,
  });

  final bool visible;
  final String semanticLabel;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? foregroundColor;
  final String? tooltip;

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
          child: ExcludeFocus(
            excluding: !visible,
            child: tooltip == null
                ? Semantics(
                    button: true,
                    label: semanticLabel,
                    child: IconButton(
                      onPressed: onPressed,
                      padding: EdgeInsets.zero,
                      icon: Icon(icon, size: 17, color: foregroundColor),
                    ),
                  )
                : IconButton(
                    tooltip: tooltip,
                    onPressed: onPressed,
                    padding: EdgeInsets.zero,
                    icon: Icon(icon, size: 17, color: foregroundColor),
                  ),
          ),
        ),
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
