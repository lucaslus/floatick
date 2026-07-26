import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/todo_tag.dart';
import 'floatick_tag_chip.dart';
import 'tag_palette.dart';

const double _tagMenuWidth = 238;
const double _tagFilterButtonDimension = 42;

class TagFilterButton extends StatelessWidget {
  const TagFilterButton({
    required this.selectedTag,
    required this.onPressed,
    super.key,
  });

  final TodoTag? selectedTag;
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
        isSelected: selectedTag != null,
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
            if (selectedTag != null)
              Positioned(
                top: -2,
                right: -3,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: TagPalette.color(selectedTag!.colorValue),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.2,
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
            if (selectedTag != null)
              Positioned(
                top: -2,
                right: -3,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: TagPalette.color(selectedTag!.colorValue),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.2,
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
  final Future<void> Function(String tagId) onToggle;
  final VoidCallback onManageTags;

  @override
  State<TagAssignmentMenu> createState() => _TagAssignmentMenuState();
}

class _TagAssignmentMenuState extends State<TagAssignmentMenu> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final assignedIds = widget.assignedTagIds.toSet();
    final assignedTags = widget.tags
        .where((tag) => assignedIds.contains(tag.id))
        .toList(growable: false);
    return MenuAnchor(
      controller: _menuController,
      consumeOutsideTap: false,
      crossAxisUnconstrained: false,
      style: _tagMenuStyle(context),
      menuChildren: <Widget>[
        SizedBox(
          width: _tagMenuWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          context.l10n.assignTagsTitle,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.manageTagsTooltip,
                      onPressed: () {
                        _menuController.close();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          widget.onManageTags();
                        });
                      },
                      icon: const Icon(Icons.settings_outlined, size: 17),
                    ),
                  ],
                ),
                if (widget.tags.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 13, 8, 10),
                    child: Text(
                      context.l10n.noTagsYetMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.48),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      primary: false,
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final tag in widget.tags)
                            _TagMenuRow(
                              key: ValueKey<String>(
                                'assign-${widget.todoId}-${tag.id}',
                              ),
                              label: tag.name,
                              color: TagPalette.color(tag.colorValue),
                              selected: assignedIds.contains(tag.id),
                              onPressed: () =>
                                  unawaited(widget.onToggle(tag.id)),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, _) {
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
                onPressed: () {
                  controller.isOpen ? controller.close() : controller.open();
                },
                padding: EdgeInsets.zero,
                icon: Icon(
                  assignedTags.isEmpty
                      ? Icons.sell_outlined
                      : Icons.sell_rounded,
                  size: 13,
                  color: assignedTags.isEmpty
                      ? null
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TagMenuRow extends StatelessWidget {
  const _TagMenuRow({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.color,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.07),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 16,
                  child: color == null
                      ? Icon(
                          Icons.layers_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.46,
                          ),
                        )
                      : Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Icon(
                  selected ? Icons.check_rounded : null,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

MenuStyle _tagMenuStyle(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return MenuStyle(
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
    elevation: const WidgetStatePropertyAll<double>(0),
    backgroundColor: WidgetStatePropertyAll<Color>(
      isDark ? const Color(0xFF222D31) : const Color(0xFFF9FBFA),
    ),
    side: WidgetStatePropertyAll<BorderSide>(
      BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08),
      ),
    ),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    shadowColor: WidgetStatePropertyAll<Color>(
      Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
    ),
  );
}
