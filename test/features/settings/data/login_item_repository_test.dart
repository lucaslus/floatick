import 'package:floatick/features/settings/data/login_item_repository.dart';
import 'package:floatick/features/settings/domain/login_item_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('floatick/login_item');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads the native login item status', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 'enabled';
        });
    final repository = MethodChannelLoginItemRepository();

    final status = await repository.loadStatus();

    expect(status, LoginItemStatus.enabled);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'loadStatus');
    expect(calls.single.arguments, isNull);
  });

  test('updates the native login item and returns its actual status', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 'requiresApproval';
        });
    final repository = MethodChannelLoginItemRepository();

    final status = await repository.setEnabled(true);

    expect(status, LoginItemStatus.requiresApproval);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'setEnabled');
    expect(calls.single.arguments, isTrue);
  });

  test('rejects an unknown native login item status', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'pending');
    final repository = MethodChannelLoginItemRepository();

    await expectLater(
      repository.loadStatus(),
      throwsA(
        isA<LoginItemFailure>().having(
          (failure) => failure.kind,
          'kind',
          LoginItemFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('wraps native update failures', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'login_item_update_failed');
        });
    final repository = MethodChannelLoginItemRepository();

    await expectLater(
      repository.setEnabled(true),
      throwsA(
        isA<LoginItemFailure>().having(
          (failure) => failure.kind,
          'kind',
          LoginItemFailureKind.update,
        ),
      ),
    );
  });
}
