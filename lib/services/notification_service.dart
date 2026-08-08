// ============================================================
// 文件名: lib/services/notification_service.dart
// 说明: 本地通知服务
// ============================================================
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_alarm/main.dart';
import 'package:smart_alarm/models/reminder.dart';
import 'package:smart_alarm/utils/constants.dart';

class NotificationService {
  static const int NOTIFICATION_ID_BASE = 1000;

  static Future<void> init() async {
    // Android初始化
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS初始化
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // 创建通知渠道
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    const androidSettings = AndroidNotificationChannel(
      AppConstants.NOTIFICATION_CHANNEL_ID,
      '闹钟提醒',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidSettings);
  }

  static void _onNotificationTap(NotificationResponse response) {
    // 点击通知处理
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // 跳转到对应提醒详情
      // 可以使用全局导航或事件总线
      print('通知点击: $payload');
    }
  }

  static void _onBackgroundNotificationTap(NotificationResponse response) {
    // 后台点击通知处理
    print('后台通知点击: ${response.payload}');
  }

  // 发送提醒通知
  static Future<void> showReminderNotification(Reminder reminder) async {
    final id = NOTIFICATION_ID_BASE + reminder.id.hashCode;

    // 构建通知详情
    const androidDetails = AndroidNotificationDetails(
      AppConstants.NOTIFICATION_CHANNEL_ID,
      '闹钟提醒',
      channelDescription: '闹钟提醒通知',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: 'alarm',
      visibility: NotificationVisibility.public,
      timeoutAfter: 60000, // 1分钟后自动取消
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'alarm_category',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 播放自定义音效
    String? soundPath = reminder.soundPath;
    if (soundPath != null && soundPath.isNotEmpty) {
      // 使用自定义音效
      try {
        final sound = NotificationSound(soundPath);
        const androidDetailsWithSound = AndroidNotificationDetails(
          AppConstants.NOTIFICATION_CHANNEL_ID,
          '闹钟提醒',
          channelDescription: '闹钟提醒通知',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: 'alarm',
          visibility: NotificationVisibility.public,
          timeoutAfter: 60000,
        );
        // 注意：flutter_local_notifications 自定义音效需要设置 sound 属性
        // 但当前版本可能不支持直接传路径，需要通过原生方式
      } catch (e) {
        print('自定义音效失败: $e');
      }
    }

    await flutterLocalNotificationsPlugin.show(
      id,
      reminder.title,
      reminder.content,
      details,
      payload: reminder.id,
    );
  }

  // 取消提醒通知
  static Future<void> cancelReminderNotification(Reminder reminder) async {
    final id = NOTIFICATION_ID_BASE + reminder.id.hashCode;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // 取消所有通知
  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}