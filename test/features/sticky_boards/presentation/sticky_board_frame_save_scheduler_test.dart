import 'package:floatick/features/sticky_boards/presentation/sticky_board_frame_save_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coalesces rapid frame changes into the latest save', (
    WidgetTester tester,
  ) async {
    final scheduler = StickyBoardFrameSaveScheduler();
    addTearDown(scheduler.cancel);
    var saveCount = 0;

    scheduler.schedule(() => saveCount += 1);
    scheduler.schedule(() => saveCount += 1);
    scheduler.schedule(() => saveCount += 1);

    await tester.pump(const Duration(milliseconds: 199));
    expect(saveCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(saveCount, 1);
  });

  testWidgets('cancel prevents a pending frame save', (
    WidgetTester tester,
  ) async {
    final scheduler = StickyBoardFrameSaveScheduler();
    var saveCount = 0;

    scheduler.schedule(() => saveCount += 1);
    scheduler.cancel();
    await tester.pump(const Duration(milliseconds: 200));

    expect(saveCount, 0);
  });
}
