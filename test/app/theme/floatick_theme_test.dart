import 'package:floatick/app/theme/floatick_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    test(
      '$brightness icon buttons use color feedback without a state fill',
      () {
        final theme = buildFloatickTheme(brightness);
        final style = theme.iconButtonTheme.style!;

        expect(
          style.overlayColor!.resolve(const <WidgetState>{WidgetState.hovered}),
          Colors.transparent,
        );
        expect(
          style.overlayColor!.resolve(const <WidgetState>{WidgetState.focused}),
          Colors.transparent,
        );
        expect(
          style.overlayColor!.resolve(const <WidgetState>{WidgetState.pressed}),
          Colors.transparent,
        );
        expect(
          style.foregroundColor!.resolve(const <WidgetState>{
            WidgetState.hovered,
          }),
          isNot(style.foregroundColor!.resolve(const <WidgetState>{})),
        );
        expect(
          style.foregroundColor!.resolve(const <WidgetState>{
            WidgetState.selected,
          }),
          theme.colorScheme.primary,
        );
      },
    );
  }
}
