import 'package:flutter/material.dart';

import '../../domain/todo_tag.dart';
import 'tag_palette.dart';

const double tagSelectionRowExtent = 44;

class TagSelectionRow extends StatelessWidget {
  const TagSelectionRow({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.tag,
    this.trailing,
    this.pending = false,
    super.key,
  });

  final TodoTag? tag;
  final String label;
  final String? trailing;
  final bool selected;
  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = tag == null ? null : TagPalette.color(tag!.colorValue);
    return Semantics(
      button: true,
      enabled: !pending,
      selected: selected,
      child: MouseRegion(
        cursor: pending ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: InkWell(
          onTap: pending ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.07),
          child: Container(
            constraints: const BoxConstraints(minHeight: tagSelectionRowExtent),
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
