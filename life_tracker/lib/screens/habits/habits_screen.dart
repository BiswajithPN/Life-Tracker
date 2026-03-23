import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/floating_glass_card.dart';
import '../../services/notification_service.dart';
import '../../services/invoice_service.dart';
import '../../services/habit_report_service.dart';

import 'dart:convert';
import '../../state/shared_prefs_provider.dart';
import '../../state/user_provider.dart';

// Persistent habit provider
final habitProvider = NotifierProvider<HabitNotifier, List<HabitItem>>(() {
  return HabitNotifier();
});

class HabitItem {
  final String id;
  final String title;
  bool completedToday;
  int streak;
  TimeOfDay reminderTime;
  bool isEveryday;

  HabitItem({
    required this.id,
    required this.title,
    this.completedToday = false,
    this.streak = 0,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
    this.isEveryday = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completedToday': completedToday,
      'streak': streak,
      'reminderHour': reminderTime.hour,
      'reminderMinute': reminderTime.minute,
      'isEveryday': isEveryday,
    };
  }

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    return HabitItem(
      id: json['id'] as String,
      title: json['title'] as String,
      completedToday: json['completedToday'] as bool? ?? false,
      streak: json['streak'] as int? ?? 0,
      reminderTime: TimeOfDay(
        hour: json['reminderHour'] as int? ?? 8,
        minute: json['reminderMinute'] as int? ?? 0,
      ),
      isEveryday: json['isEveryday'] as bool? ?? false,
    );
  }
}

class HabitNotifier extends Notifier<List<HabitItem>> {
  String get _key {
    final user = ref.read(userProvider);
    return 'habits_data_${user?.username ?? 'guest'}';
  }

  @override
  List<HabitItem> build() {
    ref.watch(userProvider); // Watch to trigger rebuild on user change
    final prefs = ref.watch(sharedPrefsProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<HabitItem> validList = [];
        for (var e in decoded) {
          try {
            validList.add(HabitItem.fromJson(e));
          } catch (_) {}
        }
        return validList;
      } catch (_) {}
    }
    return [];
  }

  void _save(List<HabitItem> newState) {
    state = newState;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_key, jsonEncode(newState.map((e) => e.toJson()).toList()));
  }

  void addHabit(String title, TimeOfDay reminderTime, bool isEveryday) {
    if (title.trim().isEmpty) return;
    
    final newHabit = HabitItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      reminderTime: reminderTime,
      isEveryday: isEveryday,
    );
    _save([...state, newHabit]);
    
    if (isEveryday) {
      NotificationService.scheduleDailyHabitReminder(
        id: newHabit.id.hashCode,
        habitName: newHabit.title,
        hour: reminderTime.hour,
        minute: reminderTime.minute,
      );
    }

    // Send immediate notification to confirm
    NotificationService.showNotification(
      id: newHabit.id.hashCode + 100,
      title: '✅ Habit Added',
      body: 'Reminder set for "${newHabit.title}" at ${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
    );
  }

  void toggleHabit(String id) {
    _save(state.map((h) {
      if (h.id == id) {
        final toggled = !h.completedToday;
        return HabitItem(
          id: h.id,
          title: h.title,
          completedToday: toggled,
          streak: toggled ? h.streak + 1 : (h.streak > 0 ? h.streak - 1 : 0),
          reminderTime: h.reminderTime,
          isEveryday: h.isEveryday,
        );
      }
      return h;
    }).toList());
  }

  void removeHabit(String id) {
    NotificationService.cancelReminder(id.hashCode);
    _save(state.where((h) => h.id != id).toList());
  }

  void updateReminderTime(String id, TimeOfDay time, bool isEveryday) {
    _save(state.map((h) {
      if (h.id == id) {
        if (isEveryday) {
          NotificationService.scheduleDailyHabitReminder(
            id: h.id.hashCode,
            habitName: h.title,
            hour: time.hour,
            minute: time.minute,
          );
        } else {
          NotificationService.cancelReminder(h.id.hashCode);
        }
        return HabitItem(
          id: h.id,
          title: h.title,
          completedToday: h.completedToday,
          streak: h.streak,
          reminderTime: time,
          isEveryday: isEveryday,
        );
      }
      return h;
    }).toList());
  }

  /// Send reminders for all habits manually
  void sendAllReminders() {
    for (final habit in state) {
      if (!habit.completedToday) {
        NotificationService.showHabitReminder(habit.title);
      }
    }
  }
}

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DAILY HABITS',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.accentPurple),
            tooltip: 'Generate Habit Report (PDF)',
            onPressed: () async {
              try {
                final user = ref.read(userProvider);
                final file = await HabitReportService.generateHabitReport(
                  username: user?.username ?? 'User',
                  habits: habits,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('🎉 Habit Report generated successfully!'),
                      backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.9),
                      action: SnackBarAction(
                        label: 'OPEN',
                        textColor: Colors.white,
                        onPressed: () => InvoiceService.openPdf(file),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error generating report: $e'), backgroundColor: AppTheme.glowingRed),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.accentCyan),
            onPressed: () => _showAddHabitDialog(context, ref),
          ),
        ],
      ),
      body: habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.track_changes, size: 64, color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No habits yet',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first habit',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3), fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Dismissible(
                  key: Key(habit.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => ref.read(habitProvider.notifier).removeHabit(habit.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.glowingRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: AppTheme.glowingRed),
                  ),
                  child: GestureDetector(
                    onTap: () => ref.read(habitProvider.notifier).toggleHabit(habit.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: FloatingGlassCard(
                        glowColor: habit.completedToday ? AppTheme.accentCyan : Colors.transparent,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: habit.completedToday ? AppTheme.accentCyan : Colors.transparent,
                                border: Border.all(
                                  color: habit.completedToday
                                      ? AppTheme.accentCyan
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: habit.completedToday
                                  ? const Icon(Icons.check, color: Colors.black, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      decoration: habit.completedToday ? TextDecoration.lineThrough : null,
                                      decorationColor: AppTheme.accentCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: habit.reminderTime,
                                      );
                                      if (time != null) {
                                        ref.read(habitProvider.notifier).updateReminderTime(habit.id, time, habit.isEveryday);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.alarm, size: 13, color: AppTheme.accentMagenta.withValues(alpha: 0.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${habit.reminderTime.hour.toString().padLeft(2, '0')}:${habit.reminderTime.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.accentMagenta.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        if (habit.isEveryday) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.repeat, size: 13, color: AppTheme.accentCyan.withValues(alpha: 0.7)),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Everyday',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.accentCyan.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPurple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🔥 ${habit.streak}',
                                style: const TextStyle(color: AppTheme.accentPurple, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    bool isEveryday = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Habit', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'e.g. Drink 2L water',
                  hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = time);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm, size: 18, color: AppTheme.accentMagenta),
                      const SizedBox(width: 10),
                      Text(
                        'Reminder: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Theme(
                    data: ThemeData(
                      unselectedWidgetColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Checkbox(
                      value: isEveryday,
                      activeColor: AppTheme.accentCyan,
                      onChanged: (val) {
                        setDialogState(() => isEveryday = val ?? false);
                      },
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Everyday (schedule repeating reminder)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(habitProvider.notifier).addHabit(controller.text, selectedTime, isEveryday);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('ADD', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
