// ============================================================
// 文件名: android/app/src/main/kotlin/com/example/smart_alarm/AlarmActivity.kt
// 说明: 闹钟提醒全屏Activity - 显示提醒界面，用户可停止
// ============================================================
package com.example.smart_alarm

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class AlarmActivity : Activity() {
    private var reminderId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 全屏显示，点亮屏幕
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        setContentView(R.layout.activity_alarm)

        reminderId = intent.getStringExtra("reminderId")

        // 获取提醒数据
        val prefs = getSharedPreferences("alarm_prefs", Context.MODE_PRIVATE)
        val title = prefs.getString("${reminderId}_title", "闹钟提醒") ?: "闹钟提醒"
        val content = prefs.getString("${reminderId}_content", "该起床啦！") ?: "该起床啦！"

        findViewById<TextView>(R.id.tv_alarm_title).text = title
        findViewById<TextView>(R.id.tv_alarm_content).text = content

        findViewById<Button>(R.id.btn_stop_alarm).setOnClickListener {
            stopAlarm()
        }

        // 按返回键停止闹钟
        findViewById<Button>(R.id.btn_snooze)?.setOnClickListener {
            // 贪睡功能：5分钟后再次提醒
            snoozeAlarm()
        }
    }

    private fun stopAlarm() {
        AlarmService.stopAlarm(this)
        finish()
    }

    private fun snoozeAlarm() {
        // 停止当前闹钟
        AlarmService.stopAlarm(this)

        // 5分钟后再次触发
        // 这里简化处理，实际可以调用setAlarm方法
        finish()
    }

    override fun onBackPressed() {
        // 按返回键停止闹钟
        stopAlarm()
        super.onBackPressed()
    }

    override fun onDestroy() {
        super.onDestroy()
        // 如果Activity被销毁但服务还在运行，停止服务
        if (AlarmService.isPlaying()) {
            AlarmService.stopAlarm(this)
        }
    }
}