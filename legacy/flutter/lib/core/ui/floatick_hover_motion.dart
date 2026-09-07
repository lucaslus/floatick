import 'package:flutter/material.dart';

abstract final class FloatickMotion {
  static const hoverDuration = Duration(milliseconds: 120);
  static const iconHoverScale = 1.05;
  static const iconPressedScale = 0.96;
  static const controlHoverScale = 1.015;
  static const controlPressedScale = 0.985;
  static const chipHoverScale = 1.025;
  static const chipPressedScale = 0.98;
  static const swatchHoverScale = 1.08;
  static const swatchPressedScale = 0.94;
  static const emphasisHoverScale = 1.08;
  static const emphasisPressedScale = 0.94;
  static const emphasisHoverTurns = -0.012;

  static Widget iconButtonForegroundBuilder(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    return _FloatickMotionTransform(
      enabled: !states.contains(WidgetState.disabled),
      hovered: states.contains(WidgetState.hovered),
      pressed: states.contains(WidgetState.pressed),
      hoverScale: iconHoverScale,
      pressedScale: iconPressedScale,
      child: child ?? const SizedBox.shrink(),
    );
  }

  static Widget buttonForegroundBuilder(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    return _FloatickMotionTransform(
      enabled: !states.contains(WidgetState.disabled),
      hovered: states.contains(WidgetState.hovered),
      pressed: states.contains(WidgetState.pressed),
      hoverScale: controlHoverScale,
      pressedScale: controlPressedScale,
      child: child ?? const SizedBox.shrink(),
    );
  }

  static Widget passthroughForegroundBuilder(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    return child ?? const SizedBox.shrink();
  }
}

class FloatickHoverMotion extends StatefulWidget {
  const FloatickHoverMotion({
    required this.child,
    this.enabled = true,
    this.hoverScale = FloatickMotion.iconHoverScale,
    this.pressedScale = FloatickMotion.iconPressedScale,
    this.hoverTurns = 0,
    this.cursor = SystemMouseCursors.click,
    super.key,
  }) : assert(hoverScale > 0),
       assert(pressedScale > 0);

  final Widget child;
  final bool enabled;
  final double hoverScale;
  final double pressedScale;
  final double hoverTurns;
  final MouseCursor cursor;

  @override
  State<FloatickHoverMotion> createState() => _FloatickHoverMotionState();
}

class _FloatickHoverMotionState extends State<FloatickHoverMotion> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _clearInteraction() {
    if (!_hovered && !_pressed) {
      return;
    }
    setState(() {
      _hovered = false;
      _pressed = false;
    });
  }

  @override
  void didUpdateWidget(covariant FloatickHoverMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && (_hovered || _pressed)) {
      _hovered = false;
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? widget.cursor : SystemMouseCursors.basic,
      onEnter: widget.enabled ? (_) => _setHovered(true) : null,
      onExit: widget.enabled ? (_) => _clearInteraction() : null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
        onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
        onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
        child: _FloatickMotionTransform(
          enabled: widget.enabled,
          hovered: _hovered,
          pressed: _pressed,
          hoverScale: widget.hoverScale,
          pressedScale: widget.pressedScale,
          hoverTurns: widget.hoverTurns,
          child: widget.child,
        ),
      ),
    );
  }
}

class _FloatickMotionTransform extends StatelessWidget {
  const _FloatickMotionTransform({
    required this.enabled,
    required this.hovered,
    required this.pressed,
    required this.hoverScale,
    required this.pressedScale,
    required this.child,
    this.hoverTurns = 0,
  });

  final bool enabled;
  final bool hovered;
  final bool pressed;
  final double hoverScale;
  final double pressedScale;
  final double hoverTurns;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final scale = pressed ? pressedScale : (hovered ? hoverScale : 1.0);
    final scaledChild = AnimatedScale(
      scale: scale,
      duration: FloatickMotion.hoverDuration,
      curve: Curves.easeOutCubic,
      child: child,
    );
    if (hoverTurns == 0) {
      return scaledChild;
    }
    return AnimatedRotation(
      turns: hovered && !pressed ? hoverTurns : 0,
      duration: FloatickMotion.hoverDuration,
      curve: Curves.easeOutCubic,
      child: scaledChild,
    );
  }
}
