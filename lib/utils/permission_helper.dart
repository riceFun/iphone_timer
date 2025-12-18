import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionHelper {
  static const String _keyPermissionsRequested = 'permissions_requested';

  static Future<void> checkAndRequestPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final requested = prefs.getBool(_keyPermissionsRequested) ?? false;

    if (!requested && context.mounted) {
      await _showPermissionDialog(context);
      await prefs.setBool(_keyPermissionsRequested, true);
    }
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          '需要开启后台权限',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '为了让倒计时在后台持续运行，需要开启以下权限：',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              '1. 电池优化 - 允许\n2. 后台常驻 - 允许\n3. 自启动 - 允许',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '点击确定后会跳转到设置页面',
              style: TextStyle(color: Colors.orange, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '稍后设置',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                const platform = MethodChannel('com.example.iphone_timer/battery');
                await platform.invokeMethod('requestBatteryOptimization');
                await Future.delayed(const Duration(milliseconds: 500));
                await platform.invokeMethod('requestAutoStart');
              } catch (e) {
                print('Error opening settings: $e');
              }
            },
            child: const Text(
              '去设置',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> openSettings() async {
    try {
      const platform = MethodChannel('com.example.iphone_timer/battery');
      await platform.invokeMethod('requestAutoStart');
    } catch (e) {
      print('Error opening settings: $e');
    }
  }
}
