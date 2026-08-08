// ============================================================
// 文件名: lib/models/reminder.dart
// 说明: 提醒数据模型
// ============================================================
class Reminder {
  final String id;
  final String title;
  final String content;
  final DateTime time;
  final String? soundPath;
  final int duration; // 提醒持续时间（秒）
  final int repeatCount; // 重复次数
  final bool enabled;
  final bool vibrate;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.soundPath,
    this.duration = 30,
    this.repeatCount = 3,
    this.enabled = true,
    this.vibrate = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 从JSON创建
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      time: DateTime.parse(json['time'] as String),
      soundPath: json['soundPath'] as String?,
      duration: json['duration'] as int? ?? 30,
      repeatCount: json['repeatCount'] as int? ?? 3,
      enabled: json['enabled'] as bool? ?? true,
      vibrate: json['vibrate'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'time': time.toIso8601String(),
      'soundPath': soundPath,
      'duration': duration,
      'repeatCount': repeatCount,
      'enabled': enabled,
      'vibrate': vibrate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 复制并修改
  Reminder copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? time,
    String? soundPath,
    int? duration,
    int? repeatCount,
    bool? enabled,
    bool? vibrate,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      time: time ?? this.time,
      soundPath: soundPath ?? this.soundPath,
      duration: duration ?? this.duration,
      repeatCount: repeatCount ?? this.repeatCount,
      enabled: enabled ?? this.enabled,
      vibrate: vibrate ?? this.vibrate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 判断是否已过期
  bool get isExpired => time.isBefore(DateTime.now());

  // 获取剩余时间描述
  String get timeRemaining {
    final now = DateTime.now();
    if (time.isBefore(now)) return '已过期';
    final diff = time.difference(now);
    if (diff.inDays > 0) {
      return '${diff.inDays}天${diff.inHours % 24}小时后';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时${diff.inMinutes % 60}分钟后';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟后';
    } else {
      return '即将提醒';
    }
  }

  // 获取格式化时间
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 获取格式化日期
  String get formattedDate {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return '今天';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (time.year == tomorrow.year &&
        time.month == tomorrow.month &&
        time.day == tomorrow.day) {
      return '明天';
    }
    return '${time.month}月${time.day}日';
  }
}