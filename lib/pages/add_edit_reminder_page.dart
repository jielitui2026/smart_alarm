import 'package:flutter/material.dart';
import 'package:smart_alarm/models/reminder.dart';
import 'package:smart_alarm/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddEditReminderPage extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderPage({super.key, this.reminder});

  @override
  State<AddEditReminderPage> createState() => _AddEditReminderPageState();
}

class _AddEditReminderPageState extends State<AddEditReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _uuid = const Uuid();

  late DateTime _selectedTime;
  String? _selectedSoundPath;
  int _selectedDuration = 30;
  int _selectedRepeatCount = 3;
  bool _vibrate = true;

  bool get isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      final r = widget.reminder!;
      _titleController.text = r.title;
      _contentController.text = r.content;
      _selectedTime = r.time;
      _selectedSoundPath = r.soundPath;
      _selectedDuration = r.duration;
      _selectedRepeatCount = r.repeatCount;
      _vibrate = r.vibrate;
    } else {
      _selectedTime = DateTime.now().add(const Duration(minutes: 5));
      _selectedTime = DateTime(
        _selectedTime.year,
        _selectedTime.month,
        _selectedTime.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
        if (_selectedTime.isBefore(DateTime.now())) {
          _selectedTime = _selectedTime.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectSound() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedSoundPath = file.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已选择音效: ${file.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('选择音效失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('提醒时间不能在过去，请选择未来的时间'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reminder = Reminder(
      id: isEditing ? widget.reminder!.id : _uuid.v4(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      time: _selectedTime,
      soundPath: _selectedSoundPath,
      duration: _selectedDuration,
      repeatCount: _selectedRepeatCount,
      vibrate: _vibrate,
      enabled: true,
    );

    Navigator.pop(context, reminder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑提醒' : '添加提醒'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '提醒标题',
                  hintText: '例如：起床、吃药、会议',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入提醒标题';
                  }
                  if (value.trim().length < 2) {
                    return '标题至少2个字符';
                  }
                  return null;
                },
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '提醒内容',
                  hintText: '详细描述提醒事项',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入提醒内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('yyyy年MM月dd日').format(_selectedTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _selectDate,
                            child: const Text('选择日期'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('HH:mm').format(_selectedTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _selectTime,
                            child: const Text('选择时间'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.music_note),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedSoundPath != null
                                  ? '已选择音效'
                                  : '使用系统默认音效',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _selectSound,
                            child: const Text('选择音效'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.timer),
                          const SizedBox(width: 12),
                          const Text('提醒时长：'),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _selectedDuration,
                            items: AppConstants.DURATION_OPTIONS.map((value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value 秒'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedDuration = value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.repeat),
                          const SizedBox(width: 12),
                          const Text('重复次数：'),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _selectedRepeatCount,
                            items: AppConstants.REPEAT_OPTIONS.map((value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value 次'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRepeatCount = value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.vibration),
                          const SizedBox(width: 12),
                          const Text('震动提醒'),
                          const Spacer(),
                          Switch(
                            value: _vibrate,
                            onChanged: (value) {
                              setState(() => _vibrate = value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isEditing ? '更新提醒' : '添加提醒',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
