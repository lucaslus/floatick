import 'package:flutter/material.dart';

import '../../../../core/ui/floatick_modal_bottom_sheet.dart';
import '../../../../core/ui/floatick_surface_metrics.dart';
import '../../../../l10n/l10n.dart';

enum TodoActionsSheetAction {
  copy,
  viewDetails,
  edit,
  assignTags,
  archive,
  removeFromStickyBoard,
  restore,
  deletePermanently,
}

Future<TodoActionsSheetAction?> showTodoActionsBottomSheet({
  required BuildContext context,
  required String todoId,
  required bool archivedScope,
  required bool showArchiveAction,
  required bool showRemoveFromStickyBoard,
}) {
  return showFloatickModalBottomSheet<TodoActionsSheetAction>(
    context: context,
    builder: (context) {
      return _TodoActionsBottomSheet(
        todoId: todoId,
        archivedScope: archivedScope,
        showArchiveAction: showArchiveAction,
        showRemoveFromStickyBoard: showRemoveFromStickyBoard,
      );
    },
  );
}

class _TodoActionsBottomSheet extends StatelessWidget {
  const _TodoActionsBottomSheet({
    required this.todoId,
    required this.archivedScope,
    required this.showArchiveAction,
    required this.showRemoveFromStickyBoard,
  });

  final String todoId;
  final bool archivedScope;
  final bool showArchiveAction;
  final bool showRemoveFromStickyBoard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMacOS = theme.platform == TargetPlatform.macOS;
    final actions = _buildActions(context);
    final mediaSize = MediaQuery.sizeOf(context);
    final desiredHeight = 82.0 + (actions.length * 48.0);
    final maxHeight = mediaSize.height * (mediaSize.width < 600 ? 0.72 : 0.58);
    final minimumHeight = maxHeight < 220 ? maxHeight : 220.0;
    final sheetHeight = desiredHeight
        .clamp(minimumHeight, maxHeight)
        .toDouble();
    final sheetBorderRadius = BorderRadius.only(
      topLeft: const Radius.circular(
        FloatickSurfaceMetrics.bottomSheetTopRadius,
      ),
      topRight: const Radius.circular(
        FloatickSurfaceMetrics.bottomSheetTopRadius,
      ),
      bottomLeft: Radius.circular(
        isMacOS ? FloatickSurfaceMetrics.panelContentRadius : 0,
      ),
      bottomRight: Radius.circular(
        isMacOS ? FloatickSurfaceMetrics.panelContentRadius : 0,
      ),
    );

    return SizedBox(
      key: const Key('todo-actions-bottom-sheet'),
      width: double.infinity,
      height: sheetHeight,
      child: DecoratedBox(
        key: const Key('todo-actions-bottom-sheet-surface'),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF202A2E) : const Color(0xFFF9FBFA),
          borderRadius: sheetBorderRadius,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.11)
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: sheetBorderRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 8, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.l10n.todoActionsSheetTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('todo-actions-bottom-sheet-close'),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    itemExtent: 48,
                    children: actions,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final localizations = context.l10n;
    return <Widget>[
      _TodoActionRow(
        key: ValueKey<String>('todo-action-copy-$todoId'),
        icon: Icons.content_copy_rounded,
        label: localizations.copyTodoAsMarkdownTooltip,
        onTap: () => _select(context, TodoActionsSheetAction.copy),
      ),
      _TodoActionRow(
        key: ValueKey<String>('todo-action-view-$todoId'),
        icon: Icons.subject_rounded,
        label: localizations.viewTodoDetailsTooltip,
        onTap: () => _select(context, TodoActionsSheetAction.viewDetails),
      ),
      if (!archivedScope) ...[
        _TodoActionRow(
          key: ValueKey<String>('todo-action-edit-$todoId'),
          icon: Icons.edit_outlined,
          label: localizations.editTodoAction,
          onTap: () => _select(context, TodoActionsSheetAction.edit),
        ),
        _TodoActionRow(
          key: ValueKey<String>('todo-action-tags-$todoId'),
          icon: Icons.sell_outlined,
          label: localizations.assignTagsTooltip,
          onTap: () => _select(context, TodoActionsSheetAction.assignTags),
        ),
        if (showArchiveAction)
          _TodoActionRow(
            key: ValueKey<String>('todo-action-archive-$todoId'),
            icon: Icons.archive_outlined,
            label: localizations.archiveTooltip,
            onTap: () => _select(context, TodoActionsSheetAction.archive),
          ),
        if (showRemoveFromStickyBoard)
          _TodoActionRow(
            key: ValueKey<String>('todo-action-remove-$todoId'),
            icon: Icons.remove_circle_outline_rounded,
            label: localizations.removeFromStickyBoardTooltip,
            onTap: () =>
                _select(context, TodoActionsSheetAction.removeFromStickyBoard),
          ),
      ] else ...[
        _TodoActionRow(
          key: ValueKey<String>('todo-action-restore-$todoId'),
          icon: Icons.unarchive_outlined,
          label: localizations.restoreTooltip,
          onTap: () => _select(context, TodoActionsSheetAction.restore),
        ),
        _TodoActionRow(
          key: ValueKey<String>('todo-action-delete-$todoId'),
          icon: Icons.delete_outline_rounded,
          label: localizations.deleteTodoPermanentlyTooltip,
          destructive: true,
          onTap: () =>
              _select(context, TodoActionsSheetAction.deletePermanently),
        ),
      ],
    ];
  }

  void _select(BuildContext context, TodoActionsSheetAction action) {
    Navigator.of(context).pop(action);
  }
}

class _TodoActionRow extends StatelessWidget {
  const _TodoActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withValues(alpha: 0.88);
    return Semantics(
      button: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
