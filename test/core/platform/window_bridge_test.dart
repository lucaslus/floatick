import 'package:floatick/core/platform/window_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('floatick/window');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configures the requested secondary window as borderless', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final bridge = MethodChannelWindowBridge();

    await bridge.configureBorderlessSecondaryWindow(
      42,
      positionAdjacentToMainWindow: true,
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'configureBorderlessSecondaryWindow');
    expect(calls.single.arguments, <String, Object>{
      'viewId': 42,
      'positionAdjacentToMainWindow': true,
    });
  });

  test('coordinates the fixed main window and native floating icon', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final bridge = MethodChannelWindowBridge();

    await bridge.setFloatingIconCount(7);
    await bridge.setPreferredTheme('dark');
    await bridge.setExpanded(true, animated: false);

    expect(calls.map((call) => call.method), <String>[
      'setFloatingIconCount',
      'setPreferredTheme',
      'setExpanded',
    ]);
    expect(calls.first.arguments, 7);
    expect(calls[1].arguments, 'dark');
    expect(calls.last.arguments, <String, bool>{
      'expanded': true,
      'animated': false,
    });
  });
}
