import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/habit.dart';
import 'calendar_service.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart'; // Import UserModel

class HabitsService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  
  // Modified to only show habits for a specific user
  Future<void> printAllHabitsFromIsar({int? userId}) async {
    try {
      final isar = Get.find<Isar>();
      
      // If userId is provided, filter by user. Otherwise show all (for admin/debug only)
      final habits = userId != null
          ? await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll()
          : await isar.habits.where().findAll();
      
      debugPrint('[Isar] ${userId != null ? "User $userId" : "All"} Habits in DB (${habits.length}):');
      for (final h in habits) {
        // Load the user link to check ownership
        await h.user.load();
        final ownerUserId = h.user.value?.id;
        
        debugPrint('  Habit: id=${h.id}, name=${h.name}, pinned=${h.isPinned}, done=${h.isDone}, userId=$ownerUserId');
      }
    } catch (e) {
      debugPrint('Error printing habits from Isar: $e');
    }
  }

  // Get all habits for a user
  Future<List<Habit>> getUserHabits(int userId) async {
    print('[HabitsService] getUserHabits called for userId: $userId');
    try {
      final isar = Get.find<Isar>();
      // Correctly filter habits by userId using the backlink
      final userHabits = await isar.habits.filter().user((q) => q.idEqualTo(userId)).findAll();
      debugPrint('[HabitsService] Habits fetched from Isar for user $userId (${userHabits.length}):');
      for (final h in userHabits) {
        debugPrint('  User Habit: id=${h.id}, name=${h.name}, pinned=${h.isPinned}, done=${h.isDone}');
        debugPrint('    Habit details: id=${h.id}, name=${h.name}');
      }
      return userHabits;
    } catch (e) {
      debugPrint('Failed to fetch habits from Isar for user $userId: $e');
      throw Exception('Failed to fetch habits for user $userId: $e');
    }
  }
  
  // Get a habit by ID
  Future<Map<String, dynamic>> getHabitById(int habitId) async {
    try {
      final response = await _apiService.get('habits/detail/${habitId}');
      
      if (response['error'] == true) {
        throw Exception(response['message']);
      }
      
      return response['data'];
    } catch (e) {
      throw Exception('Failed to fetch habit details: $e');
    }
  }
  
  // Create a new habit
  Future<int> createHabit(Habit habit) async {
    print('[HabitsService] createHabit called for: ${habit.name}');
    try {
      final isar = Get.find<Isar>();
      await isar.writeTxn(() async {
        await isar.habits.put(habit);
        // CRITICAL: Save the link to the user
        await habit.user.save();
        debugPrint('[HabitsService] Saved habit link to user: ${habit.user.value?.id}');
      });
      debugPrint('[HabitsService] Habit created: id=${habit.id}, name=${habit.name}');
      
      // Pass user ID when printing habits to ensure privacy
      final userId = habit.user.value?.id;
      await printAllHabitsFromIsar(userId: userId);
      
      return habit.id; // Return the ID for event broadcasting
    } catch (e) {
      debugPrint('Failed to create habit: $e');
      throw Exception('Failed to create habit: $e');
    }
  }
  
  // Update an existing habit
  Future<Habit?> updateHabit(Habit habit) async {
    print('[HabitsService] updateHabit called for: id=${habit.id}, name=${habit.name}');
    try {
      final isar = Get.find<Isar>();
      await isar.writeTxn(() async {
        await isar.habits.put(habit);
        // CRITICAL: Save the user link to prevent losing the relationship
        await habit.user.save();
        debugPrint('[HabitsService] Saved habit-user link in update: habitId=${habit.id}, userId=${habit.user.value?.id}');
      });
      debugPrint('[HabitsService] Habit updated: id=${habit.id}, name=${habit.name}');
      
      // Pass user ID when printing habits to ensure privacy
      final userId = habit.user.value?.id;
      await printAllHabitsFromIsar(userId: userId);
      
      return habit;
    } catch (e) {
      debugPrint('Failed to update habit: $e');
      throw Exception('Failed to update habit: $e');
    }
  }
  
  // Delete a habit
  Future<void> deleteHabit(int habitId) async {
    print('[HabitsService] deleteHabit called for id=$habitId');
    try {
      final isar = Get.find<Isar>();
      await isar.writeTxn(() async {
        await isar.habits.delete(habitId);
      });
      debugPrint('[HabitsService] Habit deleted: id=$habitId');
      await printAllHabitsFromIsar();
    } catch (e) {
      debugPrint('Failed to delete habit: $e');
      throw Exception('Failed to delete habit: $e');
    }
  }
  
  // Toggle habit completion status
  Future<Habit?> toggleHabitCompletion(UserModel user, int habitId) async {
    print('[HabitsService] toggleHabitCompletion called for user ${user.id}, habitId=$habitId');
    try {
      final isar = Get.find<Isar>();
      Habit? habit = await isar.habits.get(habitId);
      if (habit == null) {
        debugPrint('Habit not found for toggle: id=$habitId');
        return null;
      }
      
      // Set the user reference - ensure it's maintained
      habit.user.value = user;
      habit.isDone = !habit.isDone;
      
      await isar.writeTxn(() async {
        await isar.habits.put(habit);
        // CRITICAL: Save the user link to prevent losing the relationship
        await habit.user.save();
        debugPrint('[HabitsService] Saved habit-user link in toggle: habitId=$habitId, userId=${user.id}');
      });
      debugPrint('[HabitsService] Habit toggled: id=$habitId, isDone=${habit.isDone}');
      
      final CalendarService calendarService = Get.find<CalendarService>();
      final now = DateTime.now();
      final normalizedDate = DateTime(now.year, now.month, now.day);
      
      if (habit.isDone) {
        await calendarService.upsertCompletion(user, habitId, normalizedDate, completed: true);
      } else {
        await calendarService.deleteCompletion(user.id, habitId, normalizedDate);
      }
      
      await printAllHabitsFromIsar(userId: user.id);
      return habit;
    } catch (e) {
      debugPrint('Failed to toggle habit completion for user ${user.id}, habitId $habitId: $e');
      throw Exception('Failed to toggle habit completion: $e');
    }
  }
  
  // Get all habit categories
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _apiService.get('categories');
      
      if (response['error'] == true) {
        throw Exception(response['message']);
      }
      
      return response['data'];
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // ****** DEBUG FUNCTION ******
  // Links habits without a valid user link to the specified user.
  // Should ideally be run once after fixes or during development.
  // Enhanced version with better safety checks and user isolation
  Future<void> debugLinkOrphanedHabitsToUser(int userId) async {
    debugPrint('[HabitsService-DEBUG] Running debugLinkOrphanedHabitsToUser for userId: $userId');
    try {
      final isar = Get.find<Isar>();
      final user = await isar.userModels.get(userId);
      if (user == null) {
        debugPrint('[HabitsService-DEBUG] User $userId not found. Cannot link habits.');
        return;
      }
      
      // IMPORTANT: Only find habits with NO user link or NULL user link
      // This ensures we don't steal habits from other users
      final allHabits = await isar.habits.where().findAll(); 
      int linkedCount = 0;
      List<int> linkedIds = [];

      await isar.writeTxn(() async {
        for (final habit in allHabits) {
          // Load the link to check its current state
          await habit.user.load(); 
          
          // SAFETY CHECK: Only link habits that have NO user (null) or empty user link
          // This is critical for user data isolation - never take another user's habits
          if (habit.user.value == null) {
            debugPrint('[HabitsService-DEBUG] Linking orphaned habit ${habit.id} (${habit.name}) to user $userId...');
            habit.user.value = user; // Set the link target
            await isar.habits.put(habit); // Save the habit object
            await habit.user.save(); // Explicitly save the link
            linkedCount++;
            linkedIds.add(habit.id);
          }
        }
      });
      
      debugPrint('[HabitsService-DEBUG] Finished linking orphaned habits. Linked $linkedCount habits to user $userId: $linkedIds');
      
      // Print habits for this user only
      await printAllHabitsFromIsar(userId: userId);
    } catch (e) {
      debugPrint('[HabitsService-DEBUG] Error in debugLinkOrphanedHabitsToUser: $e');
    }
  }
  
  // ****** END DEBUG FUNCTION ******

}
