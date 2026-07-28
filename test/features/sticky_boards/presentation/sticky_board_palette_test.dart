import 'package:floatick/features/sticky_boards/presentation/sticky_board_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the board color across the complete themed surface', () {
    const baseColor = Color(0xFF20282C);

    final blueSurface = StickyBoardPalette.surfaceColor(
      value: StickyBoardPalette.blue,
      baseColor: baseColor,
      brightness: Brightness.dark,
    );
    final orangeSurface = StickyBoardPalette.surfaceColor(
      value: StickyBoardPalette.orange,
      baseColor: baseColor,
      brightness: Brightness.dark,
    );

    expect(blueSurface, isNot(baseColor));
    expect(orangeSurface, isNot(baseColor));
    expect(blueSurface, isNot(orangeSurface));
  });

  test('strengthens the complete board surface on hover', () {
    const baseColor = Color(0xFFF4F6F5);

    final restingSurface = StickyBoardPalette.surfaceColor(
      value: StickyBoardPalette.purple,
      baseColor: baseColor,
      brightness: Brightness.light,
    );
    final hoveredSurface = StickyBoardPalette.surfaceColor(
      value: StickyBoardPalette.purple,
      baseColor: baseColor,
      brightness: Brightness.light,
      hovered: true,
    );

    expect(hoveredSurface, isNot(restingSurface));
  });
}
