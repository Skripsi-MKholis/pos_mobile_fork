import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class for debouncing actions.
/// Useful for preventing excessive method calls, such as searching during typing.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}
