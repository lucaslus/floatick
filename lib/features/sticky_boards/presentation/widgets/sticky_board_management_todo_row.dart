import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../todos/domain/todo_item.dart';
import '../../../todos/domain/todo_tag.dart';
import '../../../todos/presentation/widgets/floatick_tag_chip.dart';

class StickyBoardManagementTodoRow extends StatefulWidget {
  const StickyBoardManagementTodoRow({
    required this.item,
    required this.tags,
    required this.assignedTagIds,
    required this.onOpenDetails,
    required this.onRemove,
    super.key,
  });

  final TodoItem item;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final VoidCallback onOpenDetails;
  final VoidCallback onRemove;

  @override
  State<StickyBoardManagementTodoRow> createState() =>
      _StickyBoardManagementTodoRowState();
}

class _StickyBoardManagementTodoRowState
    extends State<StickyBoardManagementTodoRow> {
  final FocusNode _rowFocusNode = FocusNode();

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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showRemoveAction = _isHovered || _hasFocus;
    final assignedIds = widget.assignedTagIds.toSet();
    final assignedTags = widget.tags
        .where((tag) => assignedIds.contains(tag.id))
        .toList(growable: false);

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
            ? context.l10n.completedStatus
            : context.l10n.incompleteStatus,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.fromLTRB(4, 6, 5, 6),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (theme.brightness == Brightness.dark
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
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        key: ValueKey<String>(
                          'sticky-board-managed-completion-status-${item.id}',
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
                    const SizedBox(width: 7),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: ValueKey<String>(
                            'sticky-board-managed-open-details-${item.id}',
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
                                  'sticky-board-managed-title-${item.id}',
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
                    SizedBox.square(
                      dimension: 30,
                      child: AnimatedOpacity(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 140),
                        opacity: showRemoveAction ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !showRemoveAction,
                          child: ExcludeFocus(
                            excluding: !showRemoveAction,
                            child: IconButton(
                              key: ValueKey<String>(
                                'remove-from-board-${item.id}',
                              ),
                              tooltip:
                                  context.l10n.removeFromStickyBoardTooltip,
                              onPressed: widget.onRemove,
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  key: ValueKey<String>(
                    'sticky-board-managed-metadata-${item.id}',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: 36),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 3,
                        children: <Widget>[
                          for (final tag in assignedTags)
                            FloatickTagChip(
                              key: ValueKey<String>(
                                'sticky-board-managed-tag-${item.id}-${tag.id}',
                              ),
                              tag: tag,
                              compact: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _formatTime(context, item.createdAt),
                      key: ValueKey<String>(
                        'sticky-board-managed-time-${item.id}',
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.35),
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

String _formatTime(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(date.toLocal()),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
