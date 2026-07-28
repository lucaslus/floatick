import 'dart:async';

import 'package:flutter/foundation.dart';

class StickyBoardFrameSaveScheduler {
  StickyBoardFrameSaveScheduler({
    this.delay = const Duration(milliseconds: 200),
  });

  final Duration delay;
  Timer? _timer;

  void schedule(VoidCallback save) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      save();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
