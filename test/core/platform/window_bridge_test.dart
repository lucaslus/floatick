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

  test('coordinates the fixed main window and native floating icon', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final bridge = MethodChannelWindowBridge();

    await bridge.synchronizeCollapsedState();
    await bridge.setFloatingIconCount(7);
    await bridge.setPreferredTheme('dark');
    await bridge.setExpanded(true, animated: false);

    expect(calls.map((call) => call.method), <String>[
      'synchronizeCollapsedState',
      'setFloatingIconCount',
      'setPreferredTheme',
      'setExpanded',
    ]);
    expect(calls[1].arguments, 7);
    expect(calls[2].arguments, 'dark');
    expect(calls.last.arguments, <String, bool>{
      'expanded': true,
      'animated': false,
    });
  });

  test('replays an expand request received before the UI is ready', () async {
    final bridge = MethodChannelWindowBridge();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('requestExpand', 'bottomLeft'),
      ),
      null,
    );

    final receivedAnchors = <WindowExpansionAnchor>[];
    bridge.setExpandRequestHandler(receivedAnchors.add);

    expect(receivedAnchors, <WindowExpansionAnchor>[
      WindowExpansionAnchor.bottomLeft,
    ]);
  });

  test('replays a collapse request received before the UI is ready', () async {
    final bridge = MethodChannelWindowBridge();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('requestCollapse')),
      null,
    );

    var collapseRequestCount = 0;
    bridge.setCollapseRequestHandler(() => collapseRequestCount += 1);

    expect(collapseRequestCount, 1);
  });
}
