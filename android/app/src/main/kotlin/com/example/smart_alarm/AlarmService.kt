// ============================================================
// 文件名: android/app/src/main/kotlin/com/example/smart_alarm/AlarmService.kt
// 说明: 闹钟前台服务 - 播放音效并保持后台运行
// ============================================================
package com.example.smart_alarm

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var isPlaying = false
    private var reminderId: String? = null

    companion object {
        private const val CHANNEL_ID = "alarm_service_channel"
        private const val NOTIFICATION_ID = 1001
        private var instance: AlarmService? = null

        fun stopAlarm(context: Context) {
            instance?.stopAlarmInternal()
            instance?.stopSelf()
        }

        fun isPlaying(): Boolean {
            return instance?.isPlaying ?: false
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator

        // 获取唤醒锁，保持CPU运行
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "AlarmService::WakeLock"
        )
        wakeLock?.acquire(10 * 60 * 1000L) // 10分钟超时
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            when (it.action) {
                "com.smart_alarm.START_ALARM" -> {
                    reminderId = it.getStringExtra("reminderId")
                    startAlarm(reminderId ?: "")
                    startForeground(NOTIFICATION_ID, createNotification("闹钟已触发"))
                }
                "com.smart_alarm.STOP_ALARM" -> {
                    stopAlarmInternal()
                    stopSelf()
                }
            }
        }
        return START_STICKY
    }

    private fun startAlarm(reminderId: String) {
        if (isPlaying) return
        isPlaying = true

        // 获取提醒数据（从SharedPreferences或数据库）
        val prefs = getSharedPreferences("alarm_prefs", Context.MODE_PRIVATE)
        val soundPath = prefs.getString("${reminderId}_sound", null)
        val duration = prefs.getInt("${reminderId}_duration", 30) // 默认30秒
        val repeatCount = prefs.getInt("${reminderId}_repeatCount", 3) // 默认3次

        Log.d("AlarmService", "启动闹钟: $reminderId, 音效: $soundPath, 时长: $duration, 次数: $repeatCount")

        // 播放音效
        playSound(soundPath, duration, repeatCount)

        // 震动
        vibrate()
    }

    private fun playSound(soundPath: String?, duration: Int, repeatCount: Int) {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer()

            val audioFile = if (soundPath != null && File(soundPath).exists()) {
                File(soundPath)
            } else {
                // 使用系统默认闹钟音效
                null
            }

            if (audioFile != null) {
                mediaPlayer?.setDataSource(audioFile.absolutePath)
            } else {
                // 使用系统默认闹钟音效
                val uri = android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI
                mediaPlayer?.setDataSource(this, uri)
            }

            mediaPlayer?.prepare()
            mediaPlayer?.isLooping = false

            // 播放指定次数
            var playedCount = 0
            val totalDuration = duration * 1000L // 转换为毫秒
            val startTime = System.currentTimeMillis()

            mediaPlayer?.setOnCompletionListener {
                playedCount++
                val elapsed = System.currentTimeMillis() - startTime
                if (playedCount < repeatCount && elapsed < totalDuration) {
                    // 重新播放
                    mediaPlayer?.seekTo(0)
                    mediaPlayer?.start()
                } else {
                    // 播放完成或超时
                    stopAlarmInternal()
                    stopSelf()
                }
            }

            mediaPlayer?.start()

            // 设置超时停止
            android.os.Handler(mainLooper).postDelayed({
                if (isPlaying) {
                    stopAlarmInternal()
                    stopSelf()
                }
            }, totalDuration)

        } catch (e: Exception) {
            Log.e("AlarmService", "播放音效失败: ${e.message}")
            // 播放失败时使用系统默认音效
            try {
                mediaPlayer?.release()
                mediaPlayer = MediaPlayer.create(this, android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI)
                mediaPlayer?.isLooping = true
                mediaPlayer?.start()
            } catch (ex: Exception) {
                Log.e("AlarmService", "使用默认音效也失败: ${ex.message}")
            }
        }
    }

    private fun vibrate() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createWaveform(
                        longArrayOf(0, 500, 500, 500),
                        intArrayOf(0, 255, 0, 255),
                        0
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(longArrayOf(0, 500, 500, 500), 0)
            }
        } catch (e: Exception) {
            Log.e("AlarmService", "震动失败: ${e.message}")
        }
    }

    private fun stopAlarmInternal() {
        isPlaying = false
        mediaPlayer?.apply {
            stop()
            release()
        }
        mediaPlayer = null
        vibrator?.cancel()
        wakeLock?.release()
        wakeLock = null
        Log.d("AlarmService", "闹钟已停止")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "闹钟服务",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "闹钟提醒服务，用于播放音效和震动"
                setSound(null, null)
                enableVibration(true)
                enableLights(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(content: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("⏰ 闹钟提醒")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarmInternal()
        instance = null
        Log.d("AlarmService", "服务已销毁")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}