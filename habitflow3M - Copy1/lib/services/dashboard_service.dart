import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/user.dart';

class DashboardService extends GetxService {
  final Isar isar = Get.find<Isar>();

  // Get today's habits for a specific user
  Future<List<Habit>> getTodaysHabits(Id userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get all completions for today
    final todaysCompletions = await isar.habitCompletions
        .filter()
        .user((q) => q.idEqualTo(userId))
        .dateEqualTo(today)
        .findAll();
    
    // Create a set of habitIds that have completions for today
    final completedHabitIds = todaysCompletions.map((c) => c.habitId).toSet();
    
    // Get habits for the user
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    
    debugPrint('[DashboardService] Found ${habits.length} habits for user $userId');
    debugPrint('[DashboardService] Found ${todaysCompletions.length} completions for today');
    
    // Mark as done if completed today
    for (final habit in habits) {
      habit.isDone = completedHabitIds.contains(habit.id);
    }
    
    return habits;
  }

  // Fixed method to properly calculate weekly completion rates
  Future<List<Map<String, dynamic>>> getWeeklyData(Id userId) async {
    final now = DateTime.now();
    // Get habits for the specific user
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    
    // Get and organize the habit IDs for quick lookups
    final validHabitIds = habits.map((h) => h.id).toSet();
    
    debugPrint('[DashboardService] getWeeklyData: User $userId has ${habits.length} habits with IDs: $validHabitIds');
    
    final result = <Map<String, dynamic>>[];
    
    // Print all completion records for last 7 days for debugging
    await _debugPrintCompletions(userId, days: 7);

    // Calculate dates for this week, with the current day as the last day
    // We'll go back 6 days to get a full 7-day week
    for (int i = 6; i >= 0; i--) {
      // Calculate the date for each day of the week, ending with today
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      
      // Get ALL completions for the specific user on that day
      final allCompletions = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(userId))
          .dateEqualTo(day)
          .findAll();
      
      // IMPORTANT FIX: Only count completions for habits that actually exist for this user
      final validCompletions = allCompletions.where(
        (completion) => validHabitIds.contains(completion.habitId)
      ).toList();
      
      final completed = validCompletions.length;
      final total = habits.length; // Total habits for the user
      final percentage = total > 0 ? (completed / total) * 100 : 0;
      
      // Add weekday information for display purposes (0 = Monday, ... 6 = Sunday)
      final weekday = day.weekday - 1; // Convert from DateTime weekday (1-7) to 0-6 index
      
      debugPrint('[DashboardService] Day ${day.toIso8601String()} (${_getWeekdayName(weekday)}): $completed/$total = ${percentage.toStringAsFixed(1)}%');
      debugPrint('[DashboardService] - Valid completions: ${validCompletions.map((c) => c.habitId).toList()}');
      
      result.add({
        'day': day,
        'weekday': weekday,
        'completed': completed,
        'total': total,
        'percentage': percentage,
        'isToday': day.day == now.day && day.month == now.month && day.year == now.year,
      });
    }
    return result;
  }

  // Helper method to get weekday name from index
  String _getWeekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday];
  }

  // Debug method to find problematic completion records
  Future<void> _debugPrintCompletions(Id userId, {int days = 7}) async {
    final now = DateTime.now();
    
    debugPrint('\n[DashboardService] DEBUG: ALL completions for user $userId in the last $days days:');
    
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      
      // Get ALL completions for this day
      final completions = await isar.habitCompletions
          .filter()
          .dateEqualTo(day)
          .findAll();
      
      if (completions.isEmpty) continue;
      
      debugPrint('  Date: ${day.toIso8601String().split('T')[0]}:');
      
      // Group by user
      for (final completion in completions) {
        await completion.user.load(); // Load the user link
        final completionUserId = completion.user.value?.id;
        
        debugPrint('    Completion ID: ${completion.id}, HabitID: ${completion.habitId}, '
            'UserID: $completionUserId, Completed: ${completion.completed}');
      }
    }
    
    // Also find completion records with no valid user link
    final orphanedCompletions = await isar.habitCompletions.where().findAll();
    final orphans = <HabitCompletion>[];
    
    for (final completion in orphanedCompletions) {
      await completion.user.load();
      if (completion.user.value == null) {
        orphans.add(completion);
      }
    }
    
    if (orphans.isNotEmpty) {
      debugPrint('\n[DashboardService] WARNING: Found ${orphans.length} orphaned completion records with no user:');
      for (final orphan in orphans) {
        debugPrint('  Orphaned Completion: ID=${orphan.id}, HabitID=${orphan.habitId}, Date=${orphan.date}');
      }
    }
  }
  
  // Fix this method to also check that completion records match valid habits
  Future<Map<String, dynamic>> getTodayStats(Id userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get habits for the specific user
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    final validHabitIds = habits.map((h) => h.id).toSet();
    
    // Get completions for the specific user today
    final allCompletions = await isar.habitCompletions
        .filter()
        .user((q) => q.idEqualTo(userId))
        .dateEqualTo(today)
        .findAll();
    
    // Filter completions to only count those for habits the user actually has
    final validCompletions = allCompletions.where(
      (completion) => validHabitIds.contains(completion.habitId)
    ).toList();
    
    final completionRate = habits.isNotEmpty 
        ? (validCompletions.length / habits.length) * 100 
        : 0.0;
    
    debugPrint('[DashboardService] Today stats: ${validCompletions.length}/${habits.length} = ${completionRate.toStringAsFixed(1)}%');
    
    return {
      'habitsForToday': habits.length,
      'completedHabits': validCompletions.length,
      'completionRate': completionRate,
    };
  }

  // Get current streaks for a specific user
  Future<Map<String, int>> getStreaks(Id userId) async {
    // Get habits for the specific user
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    int currentStreak = 0;
    int longestStreak = 0;
    for (var h in habits) {
      // These counts should ideally be per-habit, but for now, take the max across user's habits
      if (h.streakCount > currentStreak) currentStreak = h.streakCount;
      if (h.longestStreak > longestStreak) longestStreak = h.longestStreak;
    }
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  // Get greeting for a specific user
  Future<String> getGreeting(Id userId) async {
    final hour = DateTime.now().hour;
    String base;
    if (hour < 12) {
      base = 'Good Morning';
    } else if (hour < 17) {
      base = 'Good Afternoon';
    } else {
      base = 'Good Evening';
    }
    // Fetch the specific user by ID
    final user = await isar.userModels.get(userId);
    if (user != null) {
      return '$base, ${user.name}!';
    } else {
      // Fallback if user somehow not found (should not happen if userId is valid)
      return base;
    }
  }

  // Get reminders for a specific user (assuming reminders are per-habit)
  Future<List<Habit>> getReminders(Id userId) async {
    // Get habits for the specific user that have reminders
    return await isar.habits.filter()
               .user((q) => q.idEqualTo(userId))
               .reminderIsNotNull()
               .findAll();
  }
}
