import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/todo_item.dart';
import '../domain/todo_markdown_formatter.dart';

enum TodoCopyStatus { idle, copied, failed }

class TodoClipboardController extends ValueNotifier<TodoCopyStatus> {
  TodoClipboardController() : super(TodoCopyStatus.idle);

  static const feedbackDuration = Duration(milliseconds: 1200);

  Timer? _resetTimer;
  bool _isDisposed = false;

  Future<void> copy(TodoItem item) async {
    _resetTimer?.cancel();
    value = TodoCopyStatus.idle;
    try {
      await Clipboard.setData(
        ClipboardData(text: TodoMarkdownFormatter.format(item)),
      );
      if (!_isDisposed) {
        value = TodoCopyStatus.copied;
      }
    } on Object {
      if (!_isDisposed) {
        value = TodoCopyStatus.failed;
      }
    }
    _scheduleReset();
  }

  void reset() {
    _resetTimer?.cancel();
    if (!_isDisposed && value != TodoCopyStatus.idle) {
      value = TodoCopyStatus.idle;
    }
  }

  void _scheduleReset() {
    if (_isDisposed) {
      return;
    }
    _resetTimer = Timer(feedbackDuration, () {
      if (!_isDisposed) {
        value = TodoCopyStatus.idle;
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _resetTimer?.cancel();
    super.dispose();
  }
}
