import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BatteryService {
  static const MethodChannel _channel =
      MethodChannel('com.example.iphone_timer/battery');

  /// Request battery optimization exemption
  static Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
      debugPrint('BatteryService: Requested battery optimization exemption');
    } catch (e) {
      debugPrint('BatteryService: Failed to request battery optimization: $e');
    }
  }

  /// Request auto-start permission (for OPPO/ColorOS)
  static Future<void> requestAutoStart() async {
    try {
      await _channel.invokeMethod('requestAutoStart');
      debugPrint('BatteryService: Requested auto-start permission');
    } catch (e) {
      debugPrint('BatteryService: Failed to request auto-start: $e');
    }
  }
}
