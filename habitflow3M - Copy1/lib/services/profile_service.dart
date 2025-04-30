import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../models/activity_log.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';

class ProfileService extends GetxService {
  Isar get isar => Get.find<Isar>();

  // User Profile CRUD
  Future<UserModel?> getUserProfile(Id userId) async {
    return await isar.userModels.get(userId);
  }

  Future<void> updateUserProfile(UserModel user) async {
    // Assume user object contains the correct ID
    await isar.writeTxn(() async {
      await isar.userModels.put(user);
    });
  }

  // Achievements CRUD
  Future<List<AchievementModel>> getAchievements(Id userId) async {
    // Filter using the user link
    return await isar.achievementModels.filter().user((q) => q.idEqualTo(userId)).findAll(); 
  }

  Future<void> addAchievement(AchievementModel achievement) async {
    // Assuming achievement object has userId set correctly before calling
    await isar.writeTxn(() async {
      await isar.achievementModels.put(achievement);
    });
  }

  // Activity Log CRUD
  Future<List<ActivityLogModel>> getActivityLogs(Id userId, {int limit = 20}) async {
    // Filter using the user link
    final logs =
        await isar.activityLogModels.filter().user((q) => q.idEqualTo(userId)).sortByTimestampDesc().findAll();
    return logs.take(limit).toList();
  }

  Future<void> addActivityLog(ActivityLogModel log) async {
    // Assuming log object has userId set correctly before calling
    await isar.writeTxn(() async {
      await isar.activityLogModels.put(log);
    });
  }

  // Stats - Filtered by userId
  Future<int> getTotalHabits(Id userId) async {
    // Filter using the user link
    return await isar.habits.filter().user((q) => q.idEqualTo(userId)).count();
  }

  Future<int> getCurrentStreak(Id userId) async {
    // Filter using the user link
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.streakCount).reduce((a, b) => a > b ? a : b); // More efficient way to find max
  }

  Future<int> getLongestStreak(Id userId) async {
    // Filter using the user link
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b); // More efficient way to find max
  }

  Future<double> getWeeklyCompletionRate(Id userId) async {
    // Filter using the user link for completions and habits
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)); // Start of week (Monday)
    final weekEnd = weekStart.add(Duration(days: 7));

    final completions = await isar.habitCompletions
        .filter()
        .user((q) => q.idEqualTo(userId)) // Filter completions by user
        .dateBetween(weekStart, weekEnd, includeLower: true, includeUpper: false)
        .count();
        
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll(); // Filter habits by user
    final totalPossibleCompletions = habits.length * 7; // Total possible in a week

    if (totalPossibleCompletions == 0) return 0.0;
    return (completions / totalPossibleCompletions * 100).clamp(0.0, 100.0);
  }

  Future<double> getMonthlyCompletionRate(Id userId) async {
    // Filter using the user link for completions and habits
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of current month
    final daysInMonth = endOfMonth.day;

    final completions = await isar.habitCompletions
        .filter()
        .user((q) => q.idEqualTo(userId)) // Filter completions by user
        .dateBetween(startOfMonth, endOfMonth, includeLower: true, includeUpper: true)
        .count();
        
    final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll(); // Filter habits by user
    final totalPossibleCompletions = habits.length * daysInMonth;

    if (totalPossibleCompletions == 0) return 0.0;
    return (completions / totalPossibleCompletions * 100).clamp(0.0, 100.0);
  }

  // Weekly Activity - Filtered by userId
  Future<Map<DateTime, int>> getWeeklyActivity(Id userId) async {
    // Filter using the user link for completions
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1)); // Start of week (Monday)
    final weekEnd = weekStart.add(Duration(days: 7)); 

    final completionsList = await isar.habitCompletions
        .filter()
        .user((q) => q.idEqualTo(userId)) // Filter completions by user
        .dateBetween(weekStart, weekEnd, includeLower: true, includeUpper: false) // Between start (inclusive) and end (exclusive)
        .findAll();
        
    Map<DateTime, int> activity = {};
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      activity[day] = completionsList.where((c) => 
         c.date.year == day.year && 
         c.date.month == day.month && 
         c.date.day == day.day
      ).length;
    }
    return activity;
  }
}
