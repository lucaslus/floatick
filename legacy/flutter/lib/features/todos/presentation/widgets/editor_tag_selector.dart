import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/todo_tag.dart';
import 'floatick_tag_chip.dart';

class EditorTagSelector extends StatelessWidget {
  const EditorTagSelector({
    required this.availableTags,
    required this.selectedTagIds,
    required this.onPressed,
    this.enabled = true,
    this.buttonKey = const Key('editor-tag-button'),
    this.tagKeyPrefix = 'editor-tag',
    super.key,
  });

  final List<TodoTag> availableTags;
  final Set<String> selectedTagIds;
  final VoidCallback onPressed;
  final bool enabled;
  final Key buttonKey;
  final String tagKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final selectedTags = availableTags
        .where((tag) => selectedTagIds.contains(tag.id))
        .toList(growable: false);
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        IconButton(
          key: buttonKey,
          tooltip: context.l10n.assignTagsTooltip,
          onPressed: enabled ? onPressed : null,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(30),
            maximumSize: const Size.square(30),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: selectedTags.isEmpty
                ? theme.colorScheme.onSurface.withValues(alpha: 0.56)
                : theme.colorScheme.primary,
          ),
          icon: Icon(
            selectedTags.isEmpty ? Icons.sell_outlined : Icons.sell_rounded,
            size: 17,
          ),
        ),
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (var index = 0; index < selectedTags.length; index++) ...[
                    if (index > 0) const SizedBox(width: 5),
                    FloatickTagChip(
                      key: ValueKey<String>(
                        '$tagKeyPrefix-${selectedTags[index].id}',
                      ),
                      tag: selectedTags[index],
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
