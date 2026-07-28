import 'package:floatick/app/theme/floatick_theme.dart';
import 'package:floatick/core/ui/floatick_hover_motion.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visible application surfaces are fully opaque', () {
    expect(FloatickColors.darkSurface.a, 1);
    expect(FloatickColors.lightSurface.a, 1);
    expect(buildFloatickTheme(Brightness.dark).colorScheme.surface.a, 1);
    expect(buildFloatickTheme(Brightness.light).colorScheme.surface.a, 1);
  });

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
        expect(style.foregroundBuilder, isNotNull);
        expect(theme.textButtonTheme.style!.foregroundBuilder, isNotNull);
        expect(theme.filledButtonTheme.style!.foregroundBuilder, isNotNull);
        expect(theme.outlinedButtonTheme.style!.foregroundBuilder, isNotNull);
        expect(theme.elevatedButtonTheme.style!.foregroundBuilder, isNotNull);
      },
    );

    testWidgets('$brightness icon buttons scale on hover', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFloatickTheme(brightness),
          home: Scaffold(
            body: Center(
              child: IconButton(
                key: const Key('themed-icon-button'),
                onPressed: () {},
                icon: const Icon(Icons.settings_rounded),
              ),
            ),
          ),
        ),
      );

      final button = find.byKey(const Key('themed-icon-button'));
      expect(_buttonMotion(tester, button).scale, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(button));
      await tester.pump();

      expect(
        _buttonMotion(tester, button).scale,
        FloatickMotion.iconHoverScale,
      );
    });

    testWidgets('$brightness material buttons share the control motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFloatickTheme(brightness),
          home: Scaffold(
            body: Row(
              children: <Widget>[
                TextButton(
                  key: const Key('text-button'),
                  onPressed: () {},
                  child: const Text('Text'),
                ),
                FilledButton(
                  key: const Key('filled-button'),
                  onPressed: () {},
                  child: const Text('Filled'),
                ),
                OutlinedButton(
                  key: const Key('outlined-button'),
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                ElevatedButton(
                  key: const Key('elevated-button'),
                  onPressed: () {},
                  child: const Text('Elevated'),
                ),
              ],
            ),
          ),
        ),
      );

      for (final key in const <String>[
        'text-button',
        'filled-button',
        'outlined-button',
        'elevated-button',
      ]) {
        final button = find.byKey(Key(key));
        expect(_buttonMotion(tester, button).scale, 1);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(button));
        await tester.pump();

        expect(
          _buttonMotion(tester, button).scale,
          FloatickMotion.controlHoverScale,
        );
        await mouse.removePointer();
      }
    });
  }
}

AnimatedScale _buttonMotion(WidgetTester tester, Finder button) {
  return tester.widget<AnimatedScale>(
    find.descendant(of: button, matching: find.byType(AnimatedScale)),
  );
}
