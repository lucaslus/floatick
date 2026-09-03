import 'package:floatick/features/updates/data/update_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('floatick/update');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('maps a missing first-release feed to a typed failure', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'checkForUpdates');
      throw PlatformException(
        code: 'update_feed_unavailable',
        message: 'feed not published',
      );
    });

    final repository = MethodChannelUpdateRepository();

    await expectLater(
      repository.checkForUpdates(),
      throwsA(isA<UpdateFeedUnavailableException>()),
    );
  });

  test('preserves unexpected platform failures', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'update_feed_request_failed',
        message: 'network unavailable',
      );
    });

    final repository = MethodChannelUpdateRepository();

    await expectLater(
      repository.checkForUpdates(),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'update_feed_request_failed',
        ),
      ),
    );
  });
}
