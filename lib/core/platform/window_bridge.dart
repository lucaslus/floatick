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
typedef CollapseRequestHandler = void Function();

abstract interface class WindowBridge {
  void setExpandRequestHandler(ExpandRequestHandler? handler);

  void setCollapseRequestHandler(CollapseRequestHandler? handler);

  Future<void> synchronizeCollapsedState();

  Future<WindowExpansionAnchor> preferredExpansionAnchor();

  Future<void> setExpanded(bool expanded, {bool animated = true});

  Future<void> setFloatingIconCount(int activeCount);

  Future<void> setPreferredLanguage(String? languageCode);

  Future<void> setPreferredTheme(String themePreference);

  Future<void> setAlwaysOnTop(bool alwaysOnTop);
}

class MethodChannelWindowBridge implements WindowBridge {
  MethodChannelWindowBridge([
    this._channel = const MethodChannel('floatick/window'),
  ]) {
    _channel.setMethodCallHandler(_handleNativeMethod);
  }

  final MethodChannel _channel;
  ExpandRequestHandler? _expandRequestHandler;
  CollapseRequestHandler? _collapseRequestHandler;
  WindowExpansionAnchor? _pendingExpansionAnchor;
  bool _pendingCollapseRequest = false;

  @override
  void setExpandRequestHandler(ExpandRequestHandler? handler) {
    _expandRequestHandler = handler;
    final pendingExpansionAnchor = _pendingExpansionAnchor;
    if (handler == null || pendingExpansionAnchor == null) {
      return;
    }
    _pendingExpansionAnchor = null;
    handler(pendingExpansionAnchor);
  }

  @override
  void setCollapseRequestHandler(CollapseRequestHandler? handler) {
    _collapseRequestHandler = handler;
    if (handler == null || !_pendingCollapseRequest) {
      return;
    }
    _pendingCollapseRequest = false;
    handler();
  }

  @override
  Future<void> synchronizeCollapsedState() {
    return _channel.invokeMethod<void>('synchronizeCollapsedState');
  }

  @override
  Future<WindowExpansionAnchor> preferredExpansionAnchor() async {
    final value = await _channel.invokeMethod<String>(
      'preferredExpansionAnchor',
    );
    return WindowExpansionAnchor.fromWireValue(value);
  }

  @override
  Future<void> setExpanded(bool expanded, {bool animated = true}) {
    return _channel.invokeMethod<void>('setExpanded', <String, bool>{
      'expanded': expanded,
      'animated': animated,
    });
  }

  @override
  Future<void> setFloatingIconCount(int activeCount) {
    return _channel.invokeMethod<void>('setFloatingIconCount', activeCount);
  }

  @override
  Future<void> setPreferredLanguage(String? languageCode) {
    return _channel.invokeMethod<void>('setPreferredLanguage', languageCode);
  }

  @override
  Future<void> setPreferredTheme(String themePreference) {
    return _channel.invokeMethod<void>('setPreferredTheme', themePreference);
  }

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) {
    return _channel.invokeMethod<void>('setAlwaysOnTop', alwaysOnTop);
  }

  Future<void> _handleNativeMethod(MethodCall call) async {
    switch (call.method) {
      case 'requestExpand':
        final expansionAnchor = WindowExpansionAnchor.fromWireValue(
          call.arguments,
        );
        final handler = _expandRequestHandler;
        if (handler == null) {
          _pendingExpansionAnchor = expansionAnchor;
        } else {
          handler(expansionAnchor);
        }
        return;
      case 'requestCollapse':
        final handler = _collapseRequestHandler;
        if (handler == null) {
          _pendingCollapseRequest = true;
        } else {
          handler();
        }
        return;
      default:
        throw MissingPluginException(
          'Unsupported native method: ${call.method}',
        );
    }
  }
}
