import 'package:flutter/services.dart';

class ForegroundService {
  static const MethodChannel _channel =
      MethodChannel('com.example.iphone_timer/foreground_service');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startForegroundService');
      print('Foreground service started');
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
      print('Foreground service stopped');
    } catch (e) {
      print('Error stopping foreground service: $e');
    }
  }

  static Future<void> updateNotification(String timeRemaining) async {
    try {
      await _channel.invokeMethod('updateNotification', {'time': timeRemaining});
    } catch (e) {
      print('Error updating notification: $e');
    }
  }
}
