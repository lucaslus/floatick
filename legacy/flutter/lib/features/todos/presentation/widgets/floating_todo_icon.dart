import 'package:flutter/material.dart';

import '../../../../app/theme/floatick_theme.dart';
import '../../../../core/ui/floatick_brand_mark.dart';
import '../../../../core/ui/floatick_hover_motion.dart';
import '../../../../l10n/l10n.dart';

class FloatingTodoIcon extends StatelessWidget {
  const FloatingTodoIcon({
    required this.activeCount,
    required this.onOpen,
    super.key,
  });

  static const double canvasDimension = 72;
  static const double visualDimension = 52;

  final int activeCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: context.l10n.openApp,
        hint: context.l10n.openAppHint,
        child: FloatickHoverMotion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: SizedBox.square(
              dimension: canvasDimension,
              child: Center(
                child: SizedBox.square(
                  dimension: visualDimension + 4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 2,
                        top: 2,
                        child: FloatickBrandMark(
                          size: visualDimension,
                          shape: FloatickBrandMarkShape.circle,
                        ),
                      ),
                      if (activeCount > 0)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: _CountBadge(count: activeCount),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4.5),
      decoration: BoxDecoration(
        color: FloatickColors.orange,
        borderRadius: BorderRadius.circular(99),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
