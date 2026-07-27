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

  test('configures the requested secondary window for transparency', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final bridge = MethodChannelWindowBridge();

    await bridge.configureTransparentSecondaryWindow(42);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'configureTransparentSecondaryWindow');
    expect(calls.single.arguments, 42);
  });
}
