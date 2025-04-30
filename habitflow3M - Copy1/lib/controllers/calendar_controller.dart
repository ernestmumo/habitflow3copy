import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habitflow/models/habit.dart';
import 'package:isar/isar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/calendar_service.dart';
import '../services/event_bus.dart';
import '../models/user.dart';
import 'user_controller.dart';

class HabitRecord {
  final String id;
  final String habitId;
  final String habitName;
  final String category;
  final Color categoryColor;
  final DateTime date;
  final bool completed;

  HabitRecord({
    required this.id,
    required this.habitId,
    required this.habitName,
    required this.category,
    required this.categoryColor,
    required this.date,
    required this.completed,
  });
}

class CalendarController extends GetxController {
  final RxList<Habit> allHabits = <Habit>[].obs; // Store all habits for the current user
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final Rx<CalendarFormat> calendarFormat = CalendarFormat.month.obs;
  final RxMap<DateTime, List<HabitRecord>> habitRecords = <DateTime, List<HabitRecord>>{}.obs;
  final RxList<HabitRecord> selectedDayRecords = <HabitRecord>[].obs;
  final RxString selectedMonthOverview = ''.obs;
  final RxDouble monthlyCompletionRate = 0.0.obs;

  final CalendarService calendarService = Get.find<CalendarService>();
  final EventBus _eventBus = Get.find<EventBus>();
  final UserController _userController = Get.find<UserController>();

  @override
  void onInit() {
    super.onInit();
    debugPrint('[CalendarController] onInit called');
    
    ever(_userController.currentUser, (UserModel? user) {
      if (user != null) {
        debugPrint('[CalendarController] User changed/logged in: ${user.id}, loading data...');
        loadAllCompletions(user.id); // Load data for the new user
      } else {
        debugPrint('[CalendarController] User logged out, clearing data...');
        allHabits.clear();
        habitRecords.clear();
        selectedDayRecords.clear();
        selectedMonthOverview.value = '';
        monthlyCompletionRate.value = 0.0;
      }
    });
    
    final initialUser = _userController.currentUser.value;
    if (initialUser != null) {
      loadAllCompletions(initialUser.id);
    }
    
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _eventBus.listenToMultiple(
      [
        EventType.habitAdded,
        EventType.habitDeleted,
        EventType.habitUpdated,
        EventType.habitCompleted,
        EventType.habitUncompleted,
      ],
      (eventType, data) {
        debugPrint('[CalendarController] Received event: $eventType');
        switch (eventType) {
          case EventType.habitCompleted:
          case EventType.habitUncompleted:
            refreshCalendarData(); 
            break;
          case EventType.habitAdded:
          case EventType.habitDeleted:
            final userId = _userController.currentUserId;
            if (userId != null) {
              loadAllCompletions(userId);
            }
            break;
          case EventType.habitUpdated:
            final userId = _userController.currentUserId;
            if (userId != null) {
              loadAllCompletions(userId);
            }
            break;
          default:
            break;
        }
      },
    );
  }

  Future<void> loadAllCompletions(Id userId) async {
    debugPrint('[CalendarController] Loading all completions from Isar for user $userId...');
    final isar = Get.find<Isar>();
    final completions = await calendarService.getAllCompletions(userId); 
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    allHabits.value = habits;
    final habitMap = {for (final h in habits) h.id: h};
    final Map<DateTime, List<HabitRecord>> tempRecords = {};
    for (final c in completions) {
      final dayKey = DateTime(c.date.year, c.date.month, c.date.day);
      tempRecords.putIfAbsent(dayKey, () => []);
      final habit = habitMap[c.habitId];
      tempRecords[dayKey]!.add(HabitRecord(
        id: c.id.toString(),
        habitId: c.habitId.toString(),
        habitName: habit?.name ?? '',
        category: habit?.categoryName ?? '',
        categoryColor: Color(habit?.categoryColor ?? 0xFF2196F3),
        date: dayKey,
        completed: c.completed,
      ));
    }
    habitRecords.value = tempRecords;
    debugPrint('[CalendarController] Loaded completions for ${habitRecords.length} days');
    _updateSelectedDayRecords();
    _updateMonthStats();
  }

  void _updateSelectedDayRecords() {
    final day = DateTime(
      selectedDay.value.year, 
      selectedDay.value.month, 
      selectedDay.value.day
    );
    final completionsForDay = habitRecords[day] ?? [];
    final completedHabitIds = completionsForDay.map((r) => int.tryParse(r.habitId)).whereType<int>().toSet();
    selectedDayRecords.value = allHabits.where((habit) => habit.createdAt.isBefore(day.add(const Duration(days: 1)))).map((habit) {
      final completed = completedHabitIds.contains(habit.id);
      final completion = completionsForDay.firstWhereOrNull((r) => int.tryParse(r.habitId) == habit.id);
      return HabitRecord(
        id: completion?.id ?? habit.id.toString(),
        habitId: habit.id.toString(),
        habitName: habit.name,
        category: habit.categoryName,
        categoryColor: Color(habit.categoryColor),
        date: day,
        completed: completed,
      );
    }).toList();
  }

  void _updateMonthStats() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    int totalHabits = allHabits.length;
    int completedHabits = 0;

    for (final habit in allHabits) {
      final hasCompletion = habitRecords.entries.any((entry) =>
        entry.key.year == currentMonth.year &&
        entry.key.month == currentMonth.month &&
        entry.value.any((r) => int.tryParse(r.habitId) == habit.id && r.completed)
      );
      if (hasCompletion) completedHabits++;
    }

    monthlyCompletionRate.value = totalHabits > 0 ? (completedHabits / totalHabits) * 100 : 0.0;
    selectedMonthOverview.value =
        'Completed $completedHabits out of $totalHabits habits in ${DateFormat('MMMM').format(currentMonth)}';
  }

  Future<void> refreshCalendarData() async {
    debugPrint('[CalendarController] Refreshing calendar data...');
    final userId = _userController.currentUserId;
    if (userId == null) {
      debugPrint('[CalendarController] No user logged in, cannot refresh data.');
      allHabits.clear();
      habitRecords.clear();
      selectedDayRecords.clear();
      return; 
    }
    
    final isar = Get.find<Isar>();
    final completions = await calendarService.getAllCompletions(userId);
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    
    allHabits.value = habits; 
    final habitMap = {for (final h in habits) h.id: h};
    final Map<DateTime, List<HabitRecord>> tempRecords = {};
    
    for (final c in completions) {
      final dayKey = DateTime(c.date.year, c.date.month, c.date.day);
      tempRecords.putIfAbsent(dayKey, () => []);
      final habit = habitMap[c.habitId];
      tempRecords[dayKey]!.add(HabitRecord(
        id: c.id.toString(),
        habitId: c.habitId.toString(),
        habitName: habit?.name ?? '',
        category: habit?.categoryName ?? '',
        categoryColor: Color(habit?.categoryColor ?? 0xFF2196F3),
        date: dayKey,
        completed: c.completed,
      ));
    }
    
    habitRecords.value = tempRecords;
    
    _updateSelectedDayRecords();
    _updateMonthStats();
    update();
    
    debugPrint('[CalendarController] Calendar data refreshed');
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    this.selectedDay.value = selectedDay;
    this.focusedDay.value = focusedDay;
    _updateSelectedDayRecords();
  }

  void onFormatChanged(CalendarFormat format) {
    calendarFormat.value = format;
  }

  void onPageChanged(DateTime focusedDay) {
    this.focusedDay.value = focusedDay;
  }

  List<HabitRecord> getRecordsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    final completionsForDay = habitRecords[dayKey] ?? [];
    final completedHabitIds = completionsForDay.map((r) => int.tryParse(r.habitId)).whereType<int>().toSet();
    return allHabits.where((habit) => habit.createdAt.isBefore(dayKey.add(const Duration(days: 1)))).map((habit) {
      final completed = completedHabitIds.contains(habit.id);
      final completion = completionsForDay.firstWhereOrNull((r) => int.tryParse(r.habitId) == habit.id);
      return HabitRecord(
        id: completion?.id ?? habit.id.toString(),
        habitId: habit.id.toString(),
        habitName: habit.name,
        category: habit.categoryName,
        categoryColor: Color(habit.categoryColor),
        date: dayKey,
        completed: completed,
      );
    }).toList();
  }

  Map<String, dynamic> getDayStatistics(DateTime day) {
    final records = getRecordsForDay(day);
    final totalHabits = records.length;
    final completedHabits = records.where((record) => record.completed).length;
    final completionRate = totalHabits > 0 ? (completedHabits / totalHabits) * 100 : 0.0;
    return {
      'date': day,
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'completionRate': completionRate,
    };
  }

  Color getDayColor(DateTime day) {
    final stats = getDayStatistics(day);
    final completionRate = stats['completionRate'] as double;
    
    if (completionRate >= 80) {
      return Colors.green;
    } else if (completionRate >= 50) {
      return Colors.amber;
    } else if (completionRate > 0) {
      return Colors.red;
    } else {
      return Colors.grey.shade300;
    }
  }

  List<Map<String, dynamic>> getWeeklyData() {
    final now = DateTime.now();
    final endDay = DateTime(now.year, now.month, now.day);
    final startDay = endDay.subtract(const Duration(days: 6));
    
    List<Map<String, dynamic>> weekData = [];
    
    for (int i = 0; i < 7; i++) {
      final day = startDay.add(Duration(days: i));
      weekData.add(getDayStatistics(day));
    }
    
    return weekData;
  }

  Future<void> markHabitCompletion(int habitId, DateTime date, bool completed) async {
    final user = _userController.currentUser.value;
    if (user == null) {
      debugPrint('[CalendarController] Cannot mark completion, no user logged in.');
      return;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isAtSameMomentAs(today)) {
      await calendarService.upsertCompletion(user, habitId, date, completed: completed);
      await refreshCalendarData(); 
    } else {
      debugPrint('[CalendarController] Cannot mark completion for non-today date: ${date.toIso8601String()}');
    }
  }
}
