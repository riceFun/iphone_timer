package com.example.iphone_timer

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.concurrent.TimeUnit

class TimerForegroundService : Service() {

    companion object {
        private const val TAG = "TimerForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "timer_foreground_channel"
        const val ACTION_START = "com.example.iphone_timer.ACTION_START"
        const val ACTION_STOP = "com.example.iphone_timer.ACTION_STOP"
        const val ACTION_UPDATE = "com.example.iphone_timer.ACTION_UPDATE"
        const val ACTION_COMPLETE = "com.example.iphone_timer.ACTION_COMPLETE"
        const val ACTION_START_TIMER = "com.example.iphone_timer.ACTION_START_TIMER"
        private const val WAKELOCK_TAG = "TimerApp::TimerWakeLock"
        const val EXTRA_DURATION = "duration_seconds"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var notificationManager: NotificationManager? = null
    private val handler = Handler(Looper.getMainLooper())
    private var remainingSeconds = 0
    private var isTimerRunning = false

    private val timerRunnable = object : Runnable {
        override fun run() {
            if (remainingSeconds > 0) {
                remainingSeconds--
                updateTimerNotification()
                handler.postDelayed(this, 1000)
                Log.d(TAG, "Timer tick: $remainingSeconds seconds remaining")
            } else {
                onTimerComplete()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: action=${intent?.action}")

        when (intent?.action) {
            ACTION_START_TIMER -> {
                val duration = intent.getIntExtra(EXTRA_DURATION, 0)
                if (duration > 0) {
                    startTimer(duration)
                }
            }
            ACTION_START -> {
                acquireWakeLock()
                startForegroundService()
            }
            ACTION_UPDATE -> {
                val time = intent.getStringExtra("time") ?: ""
                updateNotification(time)
            }
            ACTION_COMPLETE -> {
                Log.d(TAG, "Timer completed via alarm")
                onTimerComplete()
            }
            ACTION_STOP -> {
                stopTimer()
                releaseWakeLock()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun startTimer(durationSeconds: Int) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "STARTING TIMER IN FOREGROUND SERVICE")
        Log.d(TAG, "Duration: $durationSeconds seconds")
        Log.d(TAG, "========================================")

        remainingSeconds = durationSeconds
        isTimerRunning = true

        acquireWakeLock()
        startForegroundService()

        handler.post(timerRunnable)
    }

    private fun stopTimer() {
        Log.d(TAG, "Stopping timer")
        isTimerRunning = false
        handler.removeCallbacks(timerRunnable)
        remainingSeconds = 0
    }

    private fun updateTimerNotification() {
        val hours = remainingSeconds / 3600
        val minutes = (remainingSeconds % 3600) / 60
        val seconds = remainingSeconds % 60

        val timeString = if (hours > 0) {
            String.format("%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d", minutes, seconds)
        }

        try {
            val notification = createNotification("剩余: $timeString")
            notificationManager?.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating notification", e)
        }
    }

    private fun onTimerComplete() {
        Log.d(TAG, "========================================")
        Log.d(TAG, "TIMER COMPLETED IN SERVICE!")
        Log.d(TAG, "========================================")

        stopTimer()

        // 获取FULL_WAKE_LOCK唤醒屏幕
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val fullWakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "TimerApp::AlarmWakeLock"
        )
        fullWakeLock.acquire(60000) // 持续1分钟

        releaseWakeLock()

        // 启动MainActivity并传递完成标志,解锁屏幕
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                     Intent.FLAG_ACTIVITY_CLEAR_TOP or
                     Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("timer_completed", true)
        }
        startActivity(mainIntent)

        // 延迟释放WakeLock
        Handler(Looper.getMainLooper()).postDelayed({
            if (fullWakeLock.isHeld) {
                fullWakeLock.release()
            }
        }, 60000)

        // 停止前台服务
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                Log.d(TAG, "WakeLock already held")
                return
            }

            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                WAKELOCK_TAG
            ).apply {
                setReferenceCounted(false)
                acquire()  // 移除超时限制，手动控制释放
            }
            Log.d(TAG, "WakeLock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring WakeLock", e)
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "WakeLock released")
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock", e)
        }
    }

    private fun startForegroundService() {
        try {
            val notification = createNotification("点击返回应用")
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "Foreground service started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service", e)
        }
    }

    private fun updateNotification(timeRemaining: String) {
        try {
            val notification = createNotification("剩余: $timeRemaining")
            notificationManager?.notify(NOTIFICATION_ID, notification)
            Log.d(TAG, "Notification updated: $timeRemaining")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating notification", e)
        }
    }

    private fun createNotification(contentText: String): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("倒计时运行中")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "倒计时前台服务",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "保持倒计时在后台运行"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)  // 不播放声音,避免干扰
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created with HIGH importance")
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy")
        releaseWakeLock()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "onTaskRemoved")
        // 不要停止服务，让倒计时继续运行
    }
}
