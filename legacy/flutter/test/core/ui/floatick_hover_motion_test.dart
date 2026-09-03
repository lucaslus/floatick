import 'package:floatick/core/ui/floatick_hover_motion.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('animates hover and press without changing layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FloatickHoverMotion(
            child: SizedBox.square(key: Key('motion-target'), dimension: 40),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('motion-target'))),
      const Size.square(40),
    );
    expect(_animatedScale(tester).scale, 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('motion-target'))),
    );
    await tester.pump();

    expect(_animatedScale(tester).scale, FloatickMotion.iconHoverScale);
    expect(
      tester.getSize(find.byKey(const Key('motion-target'))),
      const Size.square(40),
    );

    await mouse.down(tester.getCenter(find.byKey(const Key('motion-target'))));
    await tester.pump();
    expect(_animatedScale(tester).scale, FloatickMotion.iconPressedScale);

    await mouse.up();
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(_animatedScale(tester).scale, 1);
  });

  testWidgets('disables transforms when reduced motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: FloatickHoverMotion(
              hoverTurns: FloatickMotion.emphasisHoverTurns,
              child: SizedBox.square(key: Key('motion-target'), dimension: 40),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('motion-target'))),
    );
    await tester.pump();

    expect(find.byType(AnimatedScale), findsNothing);
    expect(find.byType(AnimatedRotation), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('motion-target'))),
      const Size.square(40),
    );
  });

  testWidgets('supports emphasized tilt without changing layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FloatickHoverMotion(
            hoverScale: FloatickMotion.emphasisHoverScale,
            pressedScale: FloatickMotion.emphasisPressedScale,
            hoverTurns: FloatickMotion.emphasisHoverTurns,
            child: SizedBox.square(key: Key('motion-target'), dimension: 40),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('motion-target'))),
    );
    await tester.pump();

    expect(
      tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
      FloatickMotion.emphasisHoverTurns,
    );
    expect(
      tester.getSize(find.byKey(const Key('motion-target'))),
      const Size.square(40),
    );
  });

  testWidgets('receives hover over a nested icon button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: FloatickHoverMotion(
            hoverScale: FloatickMotion.emphasisHoverScale,
            pressedScale: FloatickMotion.emphasisPressedScale,
            hoverTurns: FloatickMotion.emphasisHoverTurns,
            child: IconButton(
              key: const Key('pin-button'),
              style: const ButtonStyle(
                foregroundBuilder: FloatickMotion.passthroughForegroundBuilder,
              ),
              onPressed: () {},
              icon: const Icon(Icons.push_pin_rounded),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('pin-button'))));
    await tester.pump();

    expect(
      tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
      FloatickMotion.emphasisHoverTurns,
    );
    expect(_animatedScale(tester).scale, FloatickMotion.emphasisHoverScale);
  });
}

AnimatedScale _animatedScale(WidgetTester tester) {
  return tester.widget<AnimatedScale>(find.byType(AnimatedScale));
}
