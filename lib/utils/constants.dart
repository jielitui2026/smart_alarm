// ============================================================
// 文件名: lib/utils/constants.dart
// 说明: 常量定义
// ============================================================
class AppConstants {
  static const String APP_NAME = '智能闹钟';
  static const String NOTIFICATION_CHANNEL_ID = 'alarm_channel';
  static const String SHARED_PREFS_KEY_REMINDERS = 'reminders';

  // 提醒时长选项（秒）
  static const List<int> DURATION_OPTIONS = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  // 提醒次数选项
  static const List<int> REPEAT_OPTIONS = [1, 2, 3, 5, 10, 15, 20];

  // 默认音效路径（assets中的默认音效）
  static const String DEFAULT_SOUND_PATH = 'assets/sounds/default_alarm.mp3';
}