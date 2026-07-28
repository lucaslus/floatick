import 'package:flutter/services.dart';

import '../domain/login_item_status.dart';

abstract interface class LoginItemRepository {
  Future<LoginItemStatus> loadStatus();

  Future<LoginItemStatus> setEnabled(bool enabled);
}

class MethodChannelLoginItemRepository implements LoginItemRepository {
  static const _channel = MethodChannel('floatick/login_item');

  @override
  Future<LoginItemStatus> loadStatus() {
    return _invokeStatus(
      method: 'loadStatus',
      failureKind: LoginItemFailureKind.load,
    );
  }

  @override
  Future<LoginItemStatus> setEnabled(bool enabled) {
    return _invokeStatus(
      method: 'setEnabled',
      arguments: enabled,
      failureKind: LoginItemFailureKind.update,
    );
  }

  Future<LoginItemStatus> _invokeStatus({
    required String method,
    required LoginItemFailureKind failureKind,
    Object? arguments,
  }) async {
    try {
      final value = await _channel.invokeMethod<String>(method, arguments);
      if (value == null) {
        throw const FormatException(
          'The native login item service returned no status.',
        );
      }
      return LoginItemStatus.fromPlatformValue(value);
    } on FormatException catch (error) {
      throw LoginItemFailure(
        kind: LoginItemFailureKind.invalidResponse,
        cause: error,
      );
    } on PlatformException catch (error) {
      throw LoginItemFailure(kind: failureKind, cause: error);
    } on MissingPluginException catch (error) {
      throw LoginItemFailure(kind: failureKind, cause: error);
    }
  }
}
