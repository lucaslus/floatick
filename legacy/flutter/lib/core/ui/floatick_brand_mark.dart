import 'package:flutter/material.dart';

enum FloatickBrandMarkShape { circle, roundedSquare }

class FloatickBrandMark extends StatelessWidget {
  const FloatickBrandMark({
    required this.size,
    this.shape = FloatickBrandMarkShape.roundedSquare,
    this.shadows = const <BoxShadow>[],
    super.key,
  });

  final double size;
  final FloatickBrandMarkShape shape;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final borderRadius = switch (shape) {
      FloatickBrandMarkShape.circle => BorderRadius.circular(size / 2),
      FloatickBrandMarkShape.roundedSquare => BorderRadius.circular(
        size * 0.31,
      ),
    };

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF24383C), Color(0xFF172326)],
          ),
          border: Border.all(
            color: const Color(0xFF40575A).withValues(alpha: 0.92),
            width: size < 48 ? 1 : 1.2,
          ),
          boxShadow: shadows,
        ),
        child: const CustomPaint(painter: _FloatickDoubleCheckPainter()),
      ),
    );
  }
}

class _FloatickDoubleCheckPainter extends CustomPainter {
  const _FloatickDoubleCheckPainter();

  static const _backCheckColor = Color(0xFF1DB3A8);
  static const _frontCheckColor = Color(0xFF2CCCBD);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.07;
    final backPaint = Paint()
      ..color = _backCheckColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final frontPaint = Paint()
      ..color = _frontCheckColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final backCheck = Path()
      ..moveTo(size.width * 0.22, size.height * 0.50)
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.54,
        size.width * 0.31,
        size.height * 0.59,
        size.width * 0.36,
        size.height * 0.64,
      )
      ..cubicTo(
        size.width * 0.41,
        size.height * 0.59,
        size.width * 0.47,
        size.height * 0.52,
        size.width * 0.53,
        size.height * 0.46,
      );
    final frontCheck = Path()
      ..moveTo(size.width * 0.38, size.height * 0.50)
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.55,
        size.width * 0.47,
        size.height * 0.60,
        size.width * 0.52,
        size.height * 0.64,
      )
      ..cubicTo(
        size.width * 0.60,
        size.height * 0.55,
        size.width * 0.68,
        size.height * 0.46,
        size.width * 0.77,
        size.height * 0.37,
      );

    canvas.drawPath(backCheck, backPaint);
    canvas.drawPath(frontCheck, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _FloatickDoubleCheckPainter oldDelegate) =>
      false;
}
