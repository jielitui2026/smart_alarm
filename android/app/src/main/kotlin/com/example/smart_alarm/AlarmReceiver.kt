// ============================================================
// 文件名: android/app/src/main/kotlin/com/example/smart_alarm/AlarmReceiver.kt
// 说明: 闹钟广播接收器 - 接收系统闹钟广播并启动服务
// ============================================================
package com.example.smart_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val reminderId = intent.getStringExtra("reminderId") ?: return
            Log.d("AlarmReceiver", "收到闹钟广播: $reminderId")

            // 启动闹钟服务
            val serviceIntent = Intent(context, AlarmService::class.java).apply {
                putExtra("reminderId", reminderId)
                action = "com.smart_alarm.START_ALARM"
            }

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }

            // 同时启动 AlarmActivity 显示提醒界面
            val activityIntent = Intent(context, AlarmActivity::class.java).apply {
                putExtra("reminderId", reminderId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                addFlags(Intent.FLAG_ACTIVITY_NO_USER_ACTION)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            context.startActivity(activityIntent)

        } catch (e: Exception) {
            Log.e("AlarmReceiver", "处理闹钟广播失败: ${e.message}")
        }
    }
}