import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';

class CalendarService extends GetxService {
  // Get all habit completions for a specific user
  Future<List<HabitCompletion>> getAllCompletions(Id userId) async {
    try {
      final isar = Get.find<Isar>();
      // Filter by user link
      final completions = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(userId))
          .findAll();
      debugPrint('[CalendarService] getAllCompletions for user $userId: Found ${completions.length} completions');
      return completions;
    } catch (e) {
      debugPrint('[CalendarService] Error in getAllCompletions for user $userId: $e');
      throw Exception('Failed to fetch completions for user $userId: $e');
    }
  }

  // Get completions for a specific date for a specific user
  Future<List<HabitCompletion>> getCompletionsForDate(Id userId, DateTime date) async {
    try {
      final isar = Get.find<Isar>();
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(Duration(days: 1));
      // Filter by user link and date
      final completions = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(userId))
          .dateGreaterThan(start.subtract(const Duration(microseconds: 1)))
          .dateLessThan(end)
          .findAll();
      debugPrint('[CalendarService] getCompletionsForDate for user $userId: ${DateFormat('yyyy-MM-dd').format(date)} found ${completions.length} completions');
      return completions;
    } catch (e) {
      debugPrint('[CalendarService] Error in getCompletionsForDate for user $userId: $e');
      throw Exception('Failed to fetch completions for date for user $userId: $e');
    }
  }

  // Get monthly completions overview for a specific user
  Future<List<HabitCompletion>> getMonthlyCompletions(Id userId, int month, int year) async {
    try {
      final isar = Get.find<Isar>();
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);
      // Filter by user link and date range
      final completions = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(userId))
          .dateGreaterThan(start.subtract(const Duration(microseconds: 1)))
          .dateLessThan(end)
          .findAll();
      debugPrint('[CalendarService] getMonthlyCompletions for user $userId: $month/$year found ${completions.length} completions');
      return completions;
    } catch (e) {
      debugPrint('[CalendarService] Error in getMonthlyCompletions for user $userId: $e');
      throw Exception('Failed to fetch monthly completions for user $userId: $e');
    }
  }

  // Add or update a habit completion for a specific user
  Future<void> upsertCompletion(UserModel user, int habitId, DateTime date, {bool completed = true}) async {
    try {
      final isar = Get.find<Isar>();
      final normalizedDate = DateTime(date.year, date.month, date.day);
      // Filter by user link, habit ID, and date
      final existing = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(user.id))
          .habitIdEqualTo(habitId)
          .dateEqualTo(normalizedDate)
          .findFirst();
      
      await isar.writeTxn(() async {
        if (existing != null) {
          existing.completed = completed;
          await isar.habitCompletions.put(existing);
          debugPrint('[CalendarService] Updated completion for user ${user.id}, habitId=$habitId, date=${normalizedDate.toIso8601String()}');
        } else {
          final completion = HabitCompletion()
            ..habitId = habitId
            ..date = normalizedDate
            ..completed = completed;
          // Set the user link
          completion.user.value = user;
          await isar.habitCompletions.put(completion);
          // CRITICAL: Save the user link to ensure the relationship is persisted
          await completion.user.save();
          debugPrint('[CalendarService] Added completion for user ${user.id}, habitId=$habitId, date=${normalizedDate.toIso8601String()}');
          debugPrint('[CalendarService] Saved completion-user link: completionId=${completion.id}, userId=${user.id}');
        }
      });
    } catch (e) {
      debugPrint('[CalendarService] Error in upsertCompletion for user ${user.id}: $e');
      throw Exception('Failed to upsert completion for user ${user.id}: $e');
    }
  }

  // Delete a habit completion for a specific user
  Future<void> deleteCompletion(Id userId, int habitId, DateTime date) async {
    try {
      final isar = Get.find<Isar>();
      final normalizedDate = DateTime(date.year, date.month, date.day);
      // Filter by user link, habit ID, and date
      final existing = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(userId))
          .habitIdEqualTo(habitId)
          .dateEqualTo(normalizedDate)
          .findFirst();
          
      if (existing != null) {
        await isar.writeTxn(() async {
          await isar.habitCompletions.delete(existing.id);
        });
        debugPrint('[CalendarService] Deleted completion for user $userId, habitId=$habitId, date=${normalizedDate.toIso8601String()}');
      }
    } catch (e) {
      debugPrint('[CalendarService] Error in deleteCompletion for user $userId: $e');
      throw Exception('Failed to delete completion for user $userId: $e');
    }
  }

  // New method to clean up invalid completion records
  Future<void> cleanupInvalidCompletions(int userId) async {
    debugPrint('[CalendarService] Running cleanup for user $userId');
    try {
      final isar = Get.find<Isar>();
      
      // 1. Get all the user's valid habits
      final habits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
      final validHabitIds = habits.map((h) => h.id).toSet();
      
      debugPrint('[CalendarService] User $userId has ${habits.length} valid habits: $validHabitIds');
      
      // 2. Get all completion records for this user
      final completions = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(userId))
          .findAll();
      
      debugPrint('[CalendarService] Found ${completions.length} completion records for user $userId');
          
      // 3. Find invalid completion records (those referencing non-existent habits)
      final invalidCompletions = completions
          .where((c) => !validHabitIds.contains(c.habitId))
          .toList();
          
      if (invalidCompletions.isNotEmpty) {
        debugPrint('[CalendarService] Found ${invalidCompletions.length} invalid completion records to delete');
        
        // Log the invalid records
        for (final invalid in invalidCompletions) {
          debugPrint('  - Invalid completion: ID=${invalid.id}, HabitID=${invalid.habitId}, Date=${invalid.date}');
        }
        
        // Delete the invalid records
        await isar.writeTxn(() async {
          for (final invalid in invalidCompletions) {
            await isar.habitCompletions.delete(invalid.id);
          }
        });
        
        debugPrint('[CalendarService] Deleted ${invalidCompletions.length} invalid completion records');
      } else {
        debugPrint('[CalendarService] No invalid completion records found');
      }
      
      // 4. Also check for orphaned completions with no user
      final allCompletions = await isar.habitCompletions.where().findAll();
      final orphanedCompletions = <HabitCompletion>[];
      
      for (final completion in allCompletions) {
        await completion.user.load();
        if (completion.user.value == null) {
          orphanedCompletions.add(completion);
        }
      }
      
      if (orphanedCompletions.isNotEmpty) {
        debugPrint('[CalendarService] Found ${orphanedCompletions.length} orphaned completion records (no user)');
        
        await isar.writeTxn(() async {
          for (final orphan in orphanedCompletions) {
            await isar.habitCompletions.delete(orphan.id);
          }
        });
        
        debugPrint('[CalendarService] Deleted ${orphanedCompletions.length} orphaned completion records');
      }
      
      debugPrint('[CalendarService] Cleanup completed for user $userId');
    } catch (e) {
      debugPrint('[CalendarService] Error in cleanupInvalidCompletions: $e');
    }
  }
}
