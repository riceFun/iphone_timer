import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  static const MethodChannel _channel =
      MethodChannel('com.example.iphone_timer/alarm');

  static Function()? _onTimerComplete;

  /// Initialize the alarm service and set up method call handler
  static void initialize({Function()? onTimerComplete}) {
    _onTimerComplete = onTimerComplete;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTimerComplete') {
        debugPrint('AlarmService: Timer completed callback received');
        _onTimerComplete?.call();
      }
    });
  }

  /// Schedule an alarm to trigger after [seconds]
  static Future<void> scheduleAlarm(int seconds) async {
    try {
      await _channel.invokeMethod('scheduleAlarm', {'seconds': seconds});
      debugPrint('AlarmService: Scheduled alarm for $seconds seconds');
    } catch (e) {
      debugPrint('AlarmService: Failed to schedule alarm: $e');
    }
  }

  /// Cancel any pending alarm
  static Future<void> cancelAlarm() async {
    try {
      await _channel.invokeMethod('cancelAlarm');
      debugPrint('AlarmService: Cancelled alarm');
    } catch (e) {
      debugPrint('AlarmService: Failed to cancel alarm: $e');
    }
  }
}
