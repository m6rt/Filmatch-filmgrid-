import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class ThrottleManager {
  final Map<String, Timer> _timers = {};

  void throttle(String key, Duration duration, VoidCallback action) {
    if (!_timers.containsKey(key)) {
      action();
      _timers[key] = Timer(duration, () {
        _timers.remove(key);
      });
    }
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}

class PerformanceHelper {
  static final Map<String, Stopwatch> _stopwatches = {};

  static void startMeasure(String label) {
    if (kDebugMode) {
      _stopwatches[label] = Stopwatch()..start();
    }
  }

  static void endMeasure(String label) {
    if (kDebugMode && _stopwatches.containsKey(label)) {
      final elapsed = _stopwatches[label]!.elapsedMilliseconds;
      debugPrint('Performance [$label]: ${elapsed}ms');
      _stopwatches.remove(label);
    }
  }

  static void measureSync<T>(String label, T Function() action) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      action();
      debugPrint('Performance [$label]: ${stopwatch.elapsedMilliseconds}ms');
    } else {
      action();
    }
  }

  static Future<T> measureAsync<T>(
    String label,
    Future<T> Function() action,
  ) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      final result = await action();
      debugPrint('Performance [$label]: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } else {
      return await action();
    }
  }
}
