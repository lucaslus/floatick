import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../domain/todo_tag.dart';
import 'todo_view_model.dart';
import 'widgets/tag_palette.dart';

const double _tagFilterRowExtent = 44;

enum TagDrawerSelectionMode { filter, assignment }

class TagFilterDrawer extends StatelessWidget {
  const TagFilterDrawer.filter({
    required this.controller,
    required this.selectedTagIds,
    required this.borderOnLeft,
    required this.onToggled,
    required this.onClear,
    required this.onManageTags,
    required this.onClose,
    required this.closeFocusNode,
    super.key,
  }) : mode = TagDrawerSelectionMode.filter;

  const TagFilterDrawer.assignment({
    required this.controller,
    required this.selectedTagIds,
    required this.borderOnLeft,
    required this.onToggled,
    required this.onManageTags,
    required this.onClose,
    required this.closeFocusNode,
    super.key,
  }) : mode = TagDrawerSelectionMode.assignment,
       onClear = null;

  final TagDrawerSelectionMode mode;
  final TodoViewModel controller;
  final Set<String> selectedTagIds;
  final bool borderOnLeft;
  final ValueChanged<String> onToggled;
  final VoidCallback? onClear;
  final VoidCallback onManageTags;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAssignment = mode == TagDrawerSelectionMode.assignment;
    return DecoratedBox(
      key: Key(isAssignment ? 'tag-assignment-drawer' : 'tag-filter-drawer'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202A2E) : const Color(0xFFF9FBFA),
        border: Border(
          left: borderOnLeft
              ? BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.07),
                )
              : BorderSide.none,
          right: borderOnLeft
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.07),
                ),
        ),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final tags = controller.tags;
          final knownTagIds = tags.map((tag) => tag.id).toSet();
          final effectiveSelectedTagIds = selectedTagIds
              .where(knownTagIds.contains)
              .toSet();
          final usageCounts = controller.tagUsageCountsFor(
            tags.map((tag) => tag.id),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        isAssignment
                            ? context.l10n.assignTagsTitle
                            : context.l10n.filterByTagTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('manage-tags-button'),
                      onPressed: onManageTags,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(context.l10n.manageTagsButtonLabel),
                    ),
                    IconButton(
                      key: Key(
                        isAssignment
                            ? 'tag-assignment-close'
                            : 'tag-filter-close',
                      ),
                      focusNode: closeFocusNode,
                      tooltip: isAssignment
                          ? context.l10n.closeTagAssignmentTooltip
                          : context.l10n.closeTagFilterTooltip,
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, size: 18),
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
                child: tags.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                        children: <Widget>[
                          if (!isAssignment)
                            SizedBox(
                              height: _tagFilterRowExtent,
                              child: _TagFilterRow(
                                key: const Key('tag-filter-all'),
                                label: context.l10n.allTagsFilterLabel,
                                selected: effectiveSelectedTagIds.isEmpty,
                                onPressed: onClear!,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 28, 18, 16),
                            child: Text(
                              context.l10n.noTagsToFilterMessage,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.46,
                                ),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        key: const Key('tag-filter-list'),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                        itemExtent: _tagFilterRowExtent,
                        itemCount: tags.length + (isAssignment ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (!isAssignment && index == 0) {
                            return _TagFilterRow(
                              key: const Key('tag-filter-all'),
                              label: context.l10n.allTagsFilterLabel,
                              selected: effectiveSelectedTagIds.isEmpty,
                              onPressed: onClear!,
                            );
                          }
                          final tag = tags[index - (isAssignment ? 0 : 1)];
                          return _TagFilterRow(
                            key: ValueKey<String>(
                              '${isAssignment ? 'tag-assignment' : 'tag-filter'}-${tag.id}',
                            ),
                            tag: tag,
                            label: tag.name,
                            trailing: '${usageCounts[tag.id] ?? 0}',
                            selected: effectiveSelectedTagIds.contains(tag.id),
                            onPressed: () => onToggled(tag.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TagFilterRow extends StatelessWidget {
  const _TagFilterRow({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.tag,
    this.trailing,
    super.key,
  });

  final TodoTag? tag;
  final String label;
  final String? trailing;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = tag == null ? null : TagPalette.color(tag!.colorValue);
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.07),
          child: Container(
            constraints: const BoxConstraints(minHeight: _tagFilterRowExtent),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 18,
                  child: tagColor == null
                      ? Icon(
                          Icons.layers_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.44,
                          ),
                        )
                      : Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tagColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailing!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.40,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                SizedBox(
                  width: 18,
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 17,
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
