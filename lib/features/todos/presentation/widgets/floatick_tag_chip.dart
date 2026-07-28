import 'package:flutter/material.dart';

import '../../../../core/ui/floatick_hover_motion.dart';
import '../../domain/todo_tag.dart';
import 'tag_palette.dart';

class FloatickTagChip extends StatelessWidget {
  const FloatickTagChip({
    required this.tag,
    this.onPressed,
    this.onDeleted,
    this.compact = false,
    super.key,
  });

  final TodoTag tag;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = TagPalette.color(tag.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chip = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      height: compact ? 17 : 24,
      padding: EdgeInsets.only(
        left: compact ? 6 : 8,
        right: onDeleted == null ? (compact ? 6 : 8) : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.26 : 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 4 : 6,
            height: compact ? 4 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text(
              tag.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? color.withValues(alpha: 0.96)
                    : Color.alphaBlend(
                        Colors.black.withValues(alpha: 0.22),
                        color,
                      ),
                fontSize: compact ? 8.75 : 10.5,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 1),
            SizedBox.square(
              dimension: compact ? 17 : 19,
              child: IconButton(
                onPressed: onDeleted,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.close_rounded,
                  size: compact ? 12 : 13,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onPressed == null) {
      return chip;
    }
    return Semantics(
      button: true,
      label: tag.name,
      child: FloatickHoverMotion(
        hoverScale: FloatickMotion.chipHoverScale,
        pressedScale: FloatickMotion.chipPressedScale,
        child: GestureDetector(onTap: onPressed, child: chip),
      ),
    );
  }
}
