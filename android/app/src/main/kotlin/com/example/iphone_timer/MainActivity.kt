package com.example.iphone_timer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val FOREGROUND_CHANNEL = "com.example.iphone_timer/foreground_service"
    private val BATTERY_CHANNEL = "com.example.iphone_timer/battery"
    private val ALARM_CHANNEL = "com.example.iphone_timer/alarm"
    private val TAG = "MainActivity"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Store method channel reference for alarm callback
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)

        // Foreground service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startTimerForegroundService()
                    result.success(null)
                }
                "stopForegroundService" -> {
                    stopTimerForegroundService()
                    result.success(null)
                }
                "updateNotification" -> {
                    val time = call.argument<String>("time") ?: ""
                    updateNotification(time)
                    result.success(null)
                }
                "startTimerInService" -> {
                    val seconds = call.argument<Int>("seconds") ?: 0
                    startTimerInService(seconds)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization()
                    result.success(null)
                }
                "requestAutoStart" -> {
                    requestAutoStartPermission()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Alarm channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val seconds = call.argument<Int>("seconds") ?: 0
                    scheduleAlarm(seconds)
                    result.success(null)
                }
                "cancelAlarm" -> {
                    cancelAlarm()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent: ${intent.extras}")

        if (intent.getBooleanExtra("timer_completed", false)) {
            Log.d(TAG, "Timer completed, notifying Flutter")
            // 通知Flutter倒计时已完成
            methodChannel?.invokeMethod("onTimerComplete", null)
        }
    }

    private fun scheduleAlarm(seconds: Int) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "SCHEDULING ALARM")
        Log.d(TAG, "Duration: $seconds seconds")
        Log.d(TAG, "Current time: ${System.currentTimeMillis()}")

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, TimerAlarmReceiver::class.java).apply {
            action = TimerAlarmReceiver.ACTION_TIMER_FINISHED
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerTime = System.currentTimeMillis() + (seconds * 1000L)
        Log.d(TAG, "Trigger time: $triggerTime")
        Log.d(TAG, "Will trigger in: $seconds seconds")

        // 使用精确闹钟
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
                Log.d(TAG, "✓ Exact alarm scheduled successfully (Android 12+)")
                Log.d(TAG, "  Type: RTC_WAKEUP (will wake device)")
                Log.d(TAG, "  Method: setExactAndAllowWhileIdle")
            } else {
                Log.w(TAG, "✗ Cannot schedule exact alarms - requesting permission")
                // 引导用户授予精确闹钟权限
                val settingsIntent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                startActivity(settingsIntent)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
            Log.d(TAG, "✓ Exact alarm scheduled successfully (Android 6+)")
            Log.d(TAG, "  Type: RTC_WAKEUP (will wake device)")
            Log.d(TAG, "  Method: setExactAndAllowWhileIdle")
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
            Log.d(TAG, "✓ Exact alarm scheduled successfully")
            Log.d(TAG, "  Type: RTC_WAKEUP (will wake device)")
        }
        Log.d(TAG, "========================================")
    }

    private fun cancelAlarm() {
        Log.d(TAG, "Canceling alarm")

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, TimerAlarmReceiver::class.java).apply {
            action = TimerAlarmReceiver.ACTION_TIMER_FINISHED
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun requestAutoStartPermission() {
        try {
            // OPPO/ColorOS 自启动设置
            val intent = Intent().apply {
                action = "android.settings.APPLICATION_DETAILS_SETTINGS"
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        } catch (e: Exception) {
            // 如果打开失败，尝试打开应用设置
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            } catch (ex: Exception) {
                ex.printStackTrace()
            }
        }
    }

    private fun requestBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager

            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent().apply {
                    action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        }
    }

    private fun startTimerForegroundService() {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_START
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopTimerForegroundService() {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_STOP
        }
        startService(intent)
    }

    private fun updateNotification(time: String) {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_UPDATE
            putExtra("time", time)
        }
        startService(intent)
    }

    private fun startTimerInService(seconds: Int) {
        Log.d(TAG, "Starting timer in foreground service: $seconds seconds")
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_START_TIMER
            putExtra(TimerForegroundService.EXTRA_DURATION, seconds)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
