import 'package:flutter/services.dart';

enum WindowExpansionAnchor {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  static WindowExpansionAnchor fromWireValue(Object? value) {
    return WindowExpansionAnchor.values.firstWhere(
      (anchor) => anchor.name == value,
      orElse: () => WindowExpansionAnchor.topRight,
    );
  }
}

typedef ExpandRequestHandler =
    void Function(WindowExpansionAnchor expansionAnchor);

abstract interface class WindowBridge {
  void setExpandRequestHandler(ExpandRequestHandler? handler);

  Future<WindowExpansionAnchor> preferredExpansionAnchor();

  Future<void> setExpanded(bool expanded);

  Future<void> setPreferredLanguage(String? languageCode);

  Future<void> setAlwaysOnTop(bool alwaysOnTop);

  Future<void> configureBorderlessSecondaryWindow(int viewId);
}

class MethodChannelWindowBridge implements WindowBridge {
  MethodChannelWindowBridge() {
    _channel.setMethodCallHandler(_handleNativeMethod);
  }

  static const MethodChannel _channel = MethodChannel('floatick/window');
  ExpandRequestHandler? _expandRequestHandler;

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {
    _expandRequestHandler = handler;
  }

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    final value = await _channel.invokeMethod<String>(
      'preferredExpansionAnchor',
    );
    return WindowExpansionAnchor.fromWireValue(value);
  }

  @override
  Future<void> setExpanded(bool expanded) {
    return _channel.invokeMethod<void>('setExpanded', expanded);
  }

  @override
  Future<void> setPreferredLanguage(String? languageCode) {
    return _channel.invokeMethod<void>('setPreferredLanguage', languageCode);
  }

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) {
    return _channel.invokeMethod<void>('setAlwaysOnTop', alwaysOnTop);
  }

  @override
  Future<void> configureBorderlessSecondaryWindow(int viewId) {
    return _channel.invokeMethod<void>(
      'configureBorderlessSecondaryWindow',
      viewId,
    );
  }

  Future<void> _handleNativeMethod(MethodCall call) async {
    if (call.method == 'requestExpand') {
      _expandRequestHandler?.call(
        WindowExpansionAnchor.fromWireValue(call.arguments),
      );
      return;
    }
    throw MissingPluginException('Unsupported native method: ${call.method}');
  }
}
