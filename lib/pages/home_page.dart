// ============================================================
// 文件名: lib/pages/home_page.dart
// 说明: 主页面 - 显示提醒列表
// ============================================================
import 'package:flutter/material.dart';
import 'package:smart_alarm/models/reminder.dart';
import 'package:smart_alarm/services/alarm_service.dart';
import 'package:smart_alarm/services/notification_service.dart';
import 'package:smart_alarm/utils/constants.dart';
import 'package:smart_alarm/pages/add_edit_reminder_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await AlarmService.hasExactAlarmPermission();
    if (!hasPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('需要精确闹钟权限'),
        content: const Text(
          '为了确保闹钟准时提醒，请允许应用使用精确闹钟权限。\n\n'
          '点击"去设置"后，在系统设置中允许"闹钟和提醒"权限。',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('稍后'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AlarmService.openAlarmSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(AppConstants.SHARED_PREFS_KEY_REMINDERS) ?? [];
      _reminders = jsonList
          .map((json) => Reminder.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      // 按时间排序
      _reminders.sort((a, b) => a.time.compareTo(b.time));
    } catch (e) {
      print('加载提醒失败: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _reminders.map((r) => r.toJson()).toList();
      await prefs.setStringList(
        AppConstants.SHARED_PREFS_KEY_REMINDERS,
        jsonList.map((j) => j.toString()).toList(),
      );
    } catch (e) {
      print('保存提醒失败: $e');
    }
  }

  Future<void> _addReminder() async {
    final result = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditReminderPage(),
      ),
    );
    if (result != null) {
      setState(() {
        _reminders.add(result);
        _reminders.sort((a, b) => a.time.compareTo(b.time));
      });
      await _saveReminders();
      if (result.enabled) {
        await AlarmService.setAlarm(result);
      }
    }
  }

  Future<void> _editReminder(Reminder reminder) async {
    final result = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditReminderPage(reminder: reminder),
      ),
    );
    if (result != null) {
      final index = _reminders.indexWhere((r) => r.id == result.id);
      if (index != -1) {
        setState(() {
          _reminders[index] = result;
          _reminders.sort((a, b) => a.time.compareTo(b.time));
        });
        await _saveReminders();
        // 取消旧闹钟，设置新闹钟
        await AlarmService.cancelAlarm(reminder);
        if (result.enabled) {
          await AlarmService.setAlarm(result);
        }
      }
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除提醒'),
        content: Text('确定要删除"${reminder.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _reminders.removeWhere((r) => r.id == reminder.id);
      });
      await _saveReminders();
      await AlarmService.cancelAlarm(reminder);
      await NotificationService.cancelReminderNotification(reminder);
    }
  }

  Future<void> _toggleReminder(Reminder reminder, bool enabled) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      final updated = reminder.copyWith(enabled: enabled);
      setState(() {
        _reminders[index] = updated;
      });
      await _saveReminders();
      if (enabled) {
        await AlarmService.setAlarm(updated);
      } else {
        await AlarmService.cancelAlarm(updated);
      }
    }
  }

  String _getTimeRemainingText(Reminder reminder) {
    if (reminder.isExpired) return '已过期';
    final diff = reminder.time.difference(DateTime.now());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能闹钟'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 打开权限设置
              AlarmService.openAlarmSettings();
            },
            tooltip: '闹钟权限设置',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    return _buildReminderCard(reminder);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add),
        label: const Text('添加提醒'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有提醒',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加第一个提醒',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final isExpired = reminder.isExpired;
    final timeStr = DateFormat('HH:mm').format(reminder.time);
    final dateStr = reminder.formattedDate;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () => _editReminder(reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 状态图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: reminder.enabled
                      ? (isExpired ? Colors.grey[300] : Colors.blue[50])
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reminder.enabled
                      ? (isExpired ? Icons.alarm_off : Icons.alarm)
                      : Icons.alarm_off,
                  color: reminder.enabled
                      ? (isExpired ? Colors.grey : Colors.blue)
                      : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isExpired ? Colors.grey[600] : null,
                              decoration: isExpired
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!reminder.enabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '已禁用',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isExpired ? Colors.grey[500] : Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isExpired ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$dateStr $timeStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: isExpired ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reminder.repeatCount}次',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: isExpired ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reminder.duration}秒',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (!isExpired && reminder.enabled)
                          Text(
                            _getTimeRemainingText(reminder),
                            style: TextStyle(
                              fontSize: 12,
                              color: reminder.time
                                      .difference(DateTime.now())
                                      .inMinutes <
                                  10
                                  ? Colors.orange
                                  : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // 开关
              Switch(
                value: reminder.enabled,
                onChanged: (value) => _toggleReminder(reminder, value),
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}