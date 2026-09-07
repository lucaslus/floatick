import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'todo_view_model.dart';
import 'widgets/tag_selection_row.dart';

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
    this.usageCounts,
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
       onClear = null,
       usageCounts = null;

  final TagDrawerSelectionMode mode;
  final TodoViewModel controller;
  final Set<String> selectedTagIds;
  final bool borderOnLeft;
  final ValueChanged<String> onToggled;
  final VoidCallback? onClear;
  final VoidCallback onManageTags;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;
  final Map<String, int>? usageCounts;

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
          final resolvedUsageCounts =
              usageCounts ??
              controller.tagUsageCountsFor(tags.map((tag) => tag.id));
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
                              height: tagSelectionRowExtent,
                              child: TagSelectionRow(
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
                        itemExtent: tagSelectionRowExtent,
                        itemCount: tags.length + (isAssignment ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (!isAssignment && index == 0) {
                            return TagSelectionRow(
                              key: const Key('tag-filter-all'),
                              label: context.l10n.allTagsFilterLabel,
                              selected: effectiveSelectedTagIds.isEmpty,
                              onPressed: onClear!,
                            );
                          }
                          final tag = tags[index - (isAssignment ? 0 : 1)];
                          return TagSelectionRow(
                            key: ValueKey<String>(
                              '${isAssignment ? 'tag-assignment' : 'tag-filter'}-${tag.id}',
                            ),
                            tag: tag,
                            label: tag.name,
                            trailing: '${resolvedUsageCounts[tag.id] ?? 0}',
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
