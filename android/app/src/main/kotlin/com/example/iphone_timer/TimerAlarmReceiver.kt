package com.example.iphone_timer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class TimerAlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "TimerAlarmReceiver"
        const val ACTION_TIMER_FINISHED = "com.example.iphone_timer.TIMER_FINISHED"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "ALARM TRIGGERED! onReceive called")
        Log.d(TAG, "action=${intent.action}")
        Log.d(TAG, "timestamp=${System.currentTimeMillis()}")
        Log.d(TAG, "========================================")

        when (intent.action) {
            ACTION_TIMER_FINISHED -> {
                Log.d(TAG, "Timer finished action matched, starting services...")

                // 启动前台服务来播放声音和振动
                val serviceIntent = Intent(context, TimerForegroundService::class.java).apply {
                    action = TimerForegroundService.ACTION_COMPLETE
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                        Log.d(TAG, "Started foreground service (API 26+)")
                    } else {
                        context.startService(serviceIntent)
                        Log.d(TAG, "Started service (API <26)")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start service: ${e.message}", e)
                }

                // 启动或唤醒主Activity
                try {
                    val activityIntent = Intent(context, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        putExtra("timer_completed", true)
                    }
                    context.startActivity(activityIntent)
                    Log.d(TAG, "Started MainActivity with timer_completed flag")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start MainActivity: ${e.message}", e)
                }
            }
            else -> {
                Log.w(TAG, "Unknown action received: ${intent.action}")
            }
        }

        Log.d(TAG, "onReceive completed")
    }
}
