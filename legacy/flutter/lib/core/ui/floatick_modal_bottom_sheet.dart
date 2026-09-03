import 'package:flutter/material.dart';

import 'floatick_surface_metrics.dart';

const Duration _floatickModalTransitionDuration = Duration(milliseconds: 180);

Future<T?> showFloatickModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final theme = Theme.of(context);
  if (theme.platform != TargetPlatform.macOS) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: _modalScrimColor(theme.brightness),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      builder: builder,
    );
  }

  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: reduceMotion
        ? Duration.zero
        : _floatickModalTransitionDuration,
    pageBuilder: (routeContext, animation, secondaryAnimation) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(FloatickSurfaceMetrics.windowInset),
          child: ClipRRect(
            key: const Key('floatick-modal-surface-boundary'),
            borderRadius: BorderRadius.circular(
              FloatickSurfaceMetrics.panelContentRadius,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                FadeTransition(
                  opacity: curvedAnimation,
                  child: GestureDetector(
                    key: const Key('floatick-modal-scrim'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(routeContext).pop(),
                    child: ColoredBox(
                      color: _modalScrimColor(theme.brightness),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(curvedAnimation),
                    child: builder(routeContext),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Color _modalScrimColor(Brightness brightness) {
  return Colors.black.withValues(
    alpha: brightness == Brightness.dark ? 0.38 : 0.22,
  );
}
