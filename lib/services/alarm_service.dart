// ============================================================
// 文件名: lib/services/alarm_service.dart
// 说明: 闹钟管理服务 - 与原生交互
// ============================================================
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:smart_alarm/models/reminder.dart';
import 'package:smart_alarm/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.smart_alarm/alarm');

  // 设置闹钟
  static Future<bool> setAlarm(Reminder reminder) async {
    try {
      if (!reminder.enabled) return false;

      final timestamp = reminder.time.millisecondsSinceEpoch;
      final result = await _channel.invokeMethod('setAlarm', {
        'timestamp': timestamp,
        'reminderId': reminder.id,
      });

      // 保存提醒数据到SharedPreferences，供原生服务使用
      await _saveReminderData(reminder);

      // 同时使用Flutter的AlarmManager作为备用
      await AndroidAlarmManager.oneShot(
        Duration(milliseconds: timestamp - DateTime.now().millisecondsSinceEpoch),
        reminder.id.hashCode,
        _alarmCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        allowWhileIdle: true,
        params: reminder.id,
      );

      return result as bool? ?? true;
    } catch (e) {
      print('设置闹钟失败: $e');
      return false;
    }
  }

  // 取消闹钟
  static Future<bool> cancelAlarm(Reminder reminder) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {
        'reminderId': reminder.id,
      });

      await AndroidAlarmManager.cancel(reminder.id.hashCode);

      // 清除保存的数据
      await _clearReminderData(reminder.id);

      return true;
    } catch (e) {
      print('取消闹钟失败: $e');
      return false;
    }
  }

  // 检查精确闹钟权限
  static Future<bool> hasExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod('hasExactAlarmPermission');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  // 打开闹钟设置
  static Future<void> openAlarmSettings() async {
    try {
      await _channel.invokeMethod('openAlarmSettings');
    } catch (e) {
      print('打开闹钟设置失败: $e');
    }
  }

  // 保存提醒数据到SharedPreferences
  static Future<void> _saveReminderData(Reminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${reminder.id}_';
    await prefs.setString('${prefix}title', reminder.title);
    await prefs.setString('${prefix}content', reminder.content);
    await prefs.setString('${prefix}time', reminder.time.toIso8601String());
    if (reminder.soundPath != null) {
      await prefs.setString('${prefix}sound', reminder.soundPath!);
    }
    await prefs.setInt('${prefix}duration', reminder.duration);
    await prefs.setInt('${prefix}repeatCount', reminder.repeatCount);
    await prefs.setBool('${prefix}vibrate', reminder.vibrate);
    await prefs.setBool('${prefix}enabled', reminder.enabled);
  }

  // 清除提醒数据
  static Future<void> _clearReminderData(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('${id}_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // 闹钟回调函数 (AlarmManager触发)
  static Future<void> _alarmCallback(String? reminderId) async {
    if (reminderId == null) return;

    // 从SharedPreferences加载提醒数据
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString('${reminderId}_title') ?? '闹钟提醒';
    final content = prefs.getString('${reminderId}_content') ?? '该起床啦！';

    // 发送通知
    final reminder = Reminder(
      id: reminderId,
      title: title,
      content: content,
      time: DateTime.now(),
      soundPath: prefs.getString('${reminderId}_sound'),
      duration: prefs.getInt('${reminderId}_duration') ?? 30,
      repeatCount: prefs.getInt('${reminderId}_repeatCount') ?? 3,
      vibrate: prefs.getBool('${reminderId}_vibrate') ?? true,
    );
    await NotificationService.showReminderNotification(reminder);

    // 调用原生闹钟服务
    try {
      await _channel.invokeMethod('triggerAlarm', {
        'reminderId': reminderId,
      });
    } catch (e) {
      print('触发原生闹钟失败: $e');
    }
  }

  // 停止闹钟
  static Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (e) {
      print('停止闹钟失败: $e');
    }
  }

  // 检查闹钟是否正在播放
  static Future<bool> isAlarmPlaying() async {
    try {
      final result = await _channel.invokeMethod('isAlarmPlaying');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}