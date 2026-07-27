import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/todo_tag.dart';
import 'floatick_tag_chip.dart';
import 'tag_palette.dart';

const double _tagFilterButtonDimension = 42;

class TagFilterButton extends StatelessWidget {
  const TagFilterButton({
    required this.selectedCount,
    required this.onPressed,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox.square(
      dimension: _tagFilterButtonDimension,
      child: IconButton(
        key: const Key('tag-filter-button'),
        tooltip: context.l10n.filterByTagTooltip,
        isSelected: selectedCount > 0,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(_tagFilterButtonDimension),
          maximumSize: const Size.square(_tagFilterButtonDimension),
          padding: EdgeInsets.zero,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.055)
              : const Color(0xFFF0F4F2),
          foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.045),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const Icon(Icons.sell_outlined, size: 18),
            if (selectedCount > 0)
              Positioned(
                top: -7,
                right: -9,
                child: Container(
                  key: const Key('tag-filter-count'),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    selectedCount > 99 ? '99+' : '$selectedCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        selectedIcon: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Icon(
              Icons.sell_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            if (selectedCount > 0)
              Positioned(
                top: -7,
                right: -9,
                child: Container(
                  key: const Key('tag-filter-count'),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    selectedCount > 99 ? '99+' : '$selectedCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TagAssignmentMenu extends StatefulWidget {
  const TagAssignmentMenu({
    required this.todoId,
    required this.tags,
    required this.assignedTagIds,
    required this.onToggle,
    required this.onManageTags,
    super.key,
  });

  final String todoId;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final Future<bool> Function(String tagId) onToggle;
  final VoidCallback onManageTags;

  @override
  State<TagAssignmentMenu> createState() => _TagAssignmentMenuState();
}

class _TagAssignmentMenuState extends State<TagAssignmentMenu> {
  Future<void> _openBottomSheet() async {
    final theme = Theme.of(context);
    final shouldManageTags = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.38 : 0.22,
      ),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      builder: (context) {
        return _TagAssignmentBottomSheet(
          todoId: widget.todoId,
          tags: widget.tags,
          assignedTagIds: widget.assignedTagIds,
          onToggle: widget.onToggle,
        );
      },
    );
    if (shouldManageTags == true && mounted) {
      widget.onManageTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedIds = widget.assignedTagIds.toSet();
    final assignedTags = widget.tags
        .where((tag) => assignedIds.contains(tag.id))
        .toList(growable: false);
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final tag in assignedTags)
          FloatickTagChip(
            key: ValueKey<String>('todo-tag-${widget.todoId}-${tag.id}'),
            tag: tag,
            compact: true,
          ),
        SizedBox.square(
          dimension: 20,
          child: IconButton(
            key: ValueKey<String>('assign-tags-${widget.todoId}'),
            tooltip: context.l10n.assignTagsTooltip,
            onPressed: _openBottomSheet,
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

class _TagAssignmentBottomSheet extends StatefulWidget {
  const _TagAssignmentBottomSheet({
    required this.todoId,
    required this.tags,
    required this.assignedTagIds,
    required this.onToggle,
  });

  final String todoId;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final Future<bool> Function(String tagId) onToggle;

  @override
  State<_TagAssignmentBottomSheet> createState() =>
      _TagAssignmentBottomSheetState();
}

class _TagAssignmentBottomSheetState extends State<_TagAssignmentBottomSheet> {
  late final Set<String> _selectedTagIds;
  final Set<String> _pendingTagIds = <String>{};

  @override
  void initState() {
    super.initState();
    final knownTagIds = widget.tags.map((tag) => tag.id).toSet();
    _selectedTagIds = widget.assignedTagIds.where(knownTagIds.contains).toSet();
  }

  Future<void> _toggleTag(String tagId) async {
    if (_pendingTagIds.contains(tagId)) {
      return;
    }
    setState(() => _pendingTagIds.add(tagId));
    final saved = await widget.onToggle(tagId);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingTagIds.remove(tagId);
      if (saved && !_selectedTagIds.add(tagId)) {
        _selectedTagIds.remove(tagId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaSize = MediaQuery.sizeOf(context);
    final maxHeight = mediaSize.height * (mediaSize.width < 600 ? 0.72 : 0.52);
    final desiredHeight = widget.tags.isEmpty
        ? 220.0
        : 112.0 + (widget.tags.length * 48.0);
    final minimumHeight = maxHeight < 220 ? maxHeight : 220.0;
    final sheetHeight = desiredHeight
        .clamp(minimumHeight, maxHeight)
        .toDouble();
    return SizedBox(
      key: const Key('tag-assignment-bottom-sheet'),
      height: sheetHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF202A2E) : const Color(0xFFF9FBFA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.11)
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  key: const Key('tag-assignment-drag-handle'),
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
                        context.l10n.assignTagsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('tag-assignment-manage'),
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(context.l10n.manageTagsButtonLabel),
                    ),
                    IconButton(
                      key: const Key('tag-assignment-bottom-sheet-close'),
                      tooltip: context.l10n.closeTagAssignmentTooltip,
                      onPressed: () => Navigator.of(context).pop(false),
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
                child: widget.tags.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                          child: Text(
                            context.l10n.noTagsYetMessage,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.48,
                              ),
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                        itemCount: widget.tags.length,
                        itemBuilder: (context, index) {
                          final tag = widget.tags[index];
                          return _TagBottomSheetRow(
                            key: ValueKey<String>(
                              'assign-${widget.todoId}-${tag.id}',
                            ),
                            label: tag.name,
                            color: TagPalette.color(tag.colorValue),
                            selected: _selectedTagIds.contains(tag.id),
                            pending: _pendingTagIds.contains(tag.id),
                            onPressed: () => unawaited(_toggleTag(tag.id)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagBottomSheetRow extends StatelessWidget {
  const _TagBottomSheetRow({
    required this.label,
    required this.color,
    required this.selected,
    required this.pending,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: pending ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: InkWell(
          onTap: pending ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.07),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: 18,
                  child: Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox.square(
                  dimension: 18,
                  child: pending
                      ? const Padding(
                          padding: EdgeInsets.all(2),
                          child: CircularProgressIndicator(strokeWidth: 1.6),
                        )
                      : selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
