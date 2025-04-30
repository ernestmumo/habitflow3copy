import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habitflow/controllers/calendar_controller.dart';
import 'package:isar/isar.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/user.dart';
import '../services/habits_service.dart';
import '../services/event_bus.dart';
import 'user_controller.dart';

class HabitCategory {
  final String name;
  final Color color;
  final IconData icon;

  HabitCategory({
    required this.name,
    required this.color,
    required this.icon,
  });

  static HabitCategory get general => HabitCategory(
        name: 'General',
        color: Colors.grey,
        icon: Icons.question_mark,
      );
}

class HabitModel {
  final String id;
  final String name;
  final String description;
  final HabitCategory category;
  final DateTime createdAt;
  final Rx<int> streakCount;
  final Rx<int> longestStreak;
  final RxBool isPinned;
  final RxBool isDone;
  final List<DateTime> completedDates;
  final String reminder;

  HabitModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdAt,
    required int streakCount,
    required int longestStreak,
    required bool isPinned,
    required bool isDone,
    required this.completedDates,
    required this.reminder,
  })  : streakCount = streakCount.obs,
        longestStreak = longestStreak.obs,
        isPinned = isPinned.obs,
        isDone = isDone.obs;
}

class HabitsController extends GetxController {
  final HabitsService habitsService = Get.find<HabitsService>();
  final UserController _userController = Get.find<UserController>();
  final RxBool isLoading = false.obs; // Add isLoading state

  // Conversion: Habit (Isar) -> HabitModel (UI)
  HabitModel _habitToModel(Habit h) {
    // Reconstruct category from Isar fields, providing defaults.
    final categoryName = h.categoryName; // Isar field is non-null
    final categoryColor = Color(h.categoryColor); // Isar field non-null
    final categoryIconCodePoint = h.categoryIconCodePoint; // Isar field non-null
    final categoryIconFontFamily = h.categoryIconFontFamily; // Isar field IS nullable

    final category = categories.firstWhere(
      (c) => c.name == categoryName,
      // If not found in predefined, create one from Isar data or use general default
      orElse: () => HabitCategory(
        name: categoryName,
        color: categoryColor,
        // IconData constructor handles null fontFamily
        icon: IconData(categoryIconCodePoint, fontFamily: categoryIconFontFamily), 
      ), 
    );

    return HabitModel(
      id: h.id.toString(), 
      name: h.name, // Isar: non-null
      description: h.description ?? '', // Isar: nullable String?, Model: String
      category: category, 
      createdAt: h.createdAt, // Isar: non-null
      // Remove unnecessary '??' as Isar fields are non-nullable ints
      streakCount: h.streakCount, 
      longestStreak: h.longestStreak, 
      isPinned: h.isPinned, // Isar: non-null bool
      isDone: h.isDone, // Isar: non-null bool
      // Remove unnecessary '??' as Isar field is non-nullable List
      completedDates: h.completedDates, 
      reminder: h.reminder ?? 'No reminder', // Isar: nullable String?, Model: String
    );
  }

  // Conversion: HabitModel (UI) -> Habit (Isar)
  Habit _modelToHabit(HabitModel m, UserModel currentUser) {
    final habit = Habit()
      ..id = (m.id.isEmpty ? Isar.autoIncrement : int.tryParse(m.id) ?? Isar.autoIncrement)
      ..name = m.name
      ..description = m.description
      ..categoryName = m.category.name
      ..categoryColor = m.category.color.value
      ..categoryIconCodePoint = m.category.icon.codePoint
      ..categoryIconFontFamily = m.category.icon.fontFamily
      ..createdAt = m.createdAt
      ..streakCount = m.streakCount.value
      ..longestStreak = m.longestStreak.value
      ..isPinned = m.isPinned.value
      ..isDone = m.isDone.value
      ..completedDates = m.completedDates
      ..reminder = m.reminder;
      
    // Set the IsarLink to the current user
    habit.user.value = currentUser;
    
    return habit;
  }

  final RxList<HabitModel> habits = <HabitModel>[].obs;
  final RxList<HabitModel> filteredHabits = <HabitModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString filterType = 'All'.obs;
  final RxString sortType = 'Default'.obs;
  
  final RxList<HabitCategory> categories = <HabitCategory>[
    HabitCategory(name: 'Exercise', color: Colors.red, icon: Icons.fitness_center),
    HabitCategory(name: 'Reading', color: Colors.blue, icon: Icons.menu_book),
    HabitCategory(name: 'Meditation', color: Colors.purple, icon: Icons.spa),
    HabitCategory(name: 'Learning', color: Colors.green, icon: Icons.school),
    HabitCategory(name: 'Hydration', color: Colors.cyan, icon: Icons.water_drop),
  ].obs;
  
  @override
  void onInit() {
    super.onInit();
    // Listen to user changes
    ever(_userController.currentUser, (UserModel? user) {
      if (user != null) {
        _loadHabits(); // Load habits when user logs in
      } else {
        // Clear habits when user logs out
        habits.clear();
        filteredHabits.clear();
      }
    });
    // Initial load if user is already logged in
    if (_userController.currentUser.value != null) {
       _loadHabits();
    }
    ever(searchQuery, (_) => _filterAndSortHabits());
    ever(filterType, (_) => _filterAndSortHabits());
    ever(sortType, (_) => _filterAndSortHabits());
  }

  Future<void> _loadHabits() async {
    final userId = _userController.currentUserId;
    debugPrint('[HabitsController] _loadHabits: START - Called for user ID: $userId');
    
    if (userId == null) {
      debugPrint('[HabitsController] _loadHabits: No user logged in, clearing habits.');
      habits.clear();
      filteredHabits.clear();
      return;
    }
    
    try {
      // CRITICAL: Debug fix to ensure all habits are linked to the current user
      // This helps recover habits that were created before the user link fix
      try {
        debugPrint('[HabitsController] _loadHabits: Running debug fix to link orphaned habits...');
        await habitsService.debugLinkOrphanedHabitsToUser(userId);
      } catch (e) {
        debugPrint('[HabitsController] _loadHabits: Error running debug fix: $e');
        // Continue with normal flow even if debug fix fails
      }
      
      // Now fetch the habits for the current user
      final isarHabits = await habitsService.getUserHabits(userId); // Use current user ID
      debugPrint('[HabitsController] _loadHabits: Fetched ${isarHabits.length} raw habits from Service for user $userId');

      // Use an explicitly typed anonymous function to fix type mismatch
      final List<HabitModel> models = isarHabits
          .map<HabitModel>((Habit habit) => _habitToModel(habit))
          .toList();
      habits.value = models; // Update the master list
      debugPrint('[HabitsController] _loadHabits: Master habits list updated with ${habits.length} models.');
      _filterAndSortHabits(); // This updates filteredHabits
    } catch (e) {
      debugPrint('[HabitsController] _loadHabits: ERROR fetching habits - $e');
      // Optionally clear lists on error or handle differently
      habits.clear();
      filteredHabits.clear();
    }
    debugPrint('[HabitsController] _loadHabits: END');
  }

  Future<void> toggleHabitCompletion(int habitId) async {
    final user = _userController.currentUser.value; // Get current user
    if (user == null) {
      debugPrint('[HabitsController] Cannot toggle habit, no user logged in.');
      // Optionally show a message to the user
      Get.snackbar('Error', 'You must be logged in to update habits.');
      return;
    }

    isLoading.value = true;
    try {
      // Pass the UserModel to the service method
      final updatedHabit = await habitsService.toggleHabitCompletion(user, habitId);
      if (updatedHabit != null) {
        // Find the index of the habit in the list
        final habitIndex = habits.indexWhere((h) => int.parse(h.id) == habitId);
        if (habitIndex >= 0) {
          // Update the habit in the list
          habits[habitIndex] = _habitToModel(updatedHabit);
          // CRITICAL: Refresh the filtered list for the UI
          _filterAndSortHabits(); 
          debugPrint('[HabitsController] Refreshed filtered habits after toggle.');
          // Trigger event for other parts of the app (e.g., calendar)
          Get.find<EventBus>().fire(updatedHabit.isDone ? EventType.habitCompleted : EventType.habitUncompleted, data: {'habitId': habitId});
        } else {
          // Handle case where habit might not be found or toggle failed
          Get.snackbar('Error', 'Failed to update habit status.');
        }
      } else {
        // Handle case where habit might not be found or toggle failed
        Get.snackbar('Error', 'Failed to update habit status.');
      }
    } catch (e) {
      debugPrint('[HabitsController] toggleHabitCompletion error: $e');
      Get.snackbar('Error', 'Failed to update habit status.');
    } finally {
      isLoading.value = false;
    }
  }

  void togglePinned(String habitId) {
    final index = habits.indexWhere((habit) => habit.id == habitId);
    final user = _userController.currentUser.value;
    if (index != -1 && user != null) { // Check user is not null
      habits[index].isPinned.value = !habits[index].isPinned.value;
      _filterAndSortHabits();
      
      // Update the pin status in database
      final habit = _modelToHabit(habits[index], user); // Pass user
      habitsService.updateHabit(habit); // Removed saveLink
      
      // Notify other controllers
      Get.find<EventBus>().fire(EventType.habitUpdated, data: {
        'habitId': int.parse(habitId),
        'isPinned': habits[index].isPinned.value,
      });
    }
  }

  Future<void> addHabit(HabitModel habitModel) async {
    debugPrint('[HabitsController] addHabit called');
    isLoading.value = true; // Set loading state
    try {
      final user = _userController.currentUser.value;
      if (user == null) {
        debugPrint('[HabitsController] Cannot add habit, no user logged in.');
        Get.snackbar('Error', 'User not logged in.', snackPosition: SnackPosition.BOTTOM);
        return; // Cannot add habit without a user
      }
      
      final habit = _modelToHabit(habitModel, user); // Pass current user
      final newId = await habitsService.createHabit(habit); // Removed saveLink
      debugPrint('[HabitsController] Habit added with ID: $newId, reloading habits...');
      await _loadHabits();
      
      // Broadcast the event
      Get.find<EventBus>().fire(EventType.habitAdded, data: {
        'habitId': newId,
        'habitName': habitModel.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Immediately refresh calendar so UI updates
      Get.find<CalendarController>().refreshCalendarData();
    } catch (e) {
      debugPrint('[HabitsController] Error adding habit: $e');
      Get.snackbar('Error', 'Failed to add habit: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false; // Reset loading state
    }
  }

  Future<void> updateHabit(HabitModel updatedHabitModel) async {
    final user = _userController.currentUser.value;
    if (user == null) return; // Need user context
    
    final habit = _modelToHabit(updatedHabitModel, user); // Pass user
    await habitsService.updateHabit(habit); // Removed saveLink
    await _loadHabits();
    
    // Broadcast the event
    Get.find<EventBus>().fire(EventType.habitUpdated, data: {
      'habitId': int.parse(updatedHabitModel.id),
      'habitName': updatedHabitModel.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteHabit(int habitId) async {
    final userId = _userController.currentUserId;
    if (userId == null) return;
    
    // Get habit name before deletion for the event
    final habitName = habits.firstWhereOrNull((h) => int.parse(h.id) == habitId)?.name ?? 'Unknown';
    
    await habitsService.deleteHabit(habitId); // Removed userId
    await _loadHabits();
    
    // Broadcast the event
    Get.find<EventBus>().fire(EventType.habitDeleted, data: {
      'habitId': habitId,
      'habitName': habitName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setFilterType(String type) {
    filterType.value = type;
  }

  void setSortType(String type) {
    sortType.value = type;
  }

  void _filterAndSortHabits() {
    debugPrint('[HabitsController] _filterAndSortHabits: START - Master habits count: ${habits.length}');
    debugPrint('[HabitsController] _filterAndSortHabits: Current Filter: ${filterType.value}, Sort: ${sortType.value}, Search: "${searchQuery.value}"');

    // Apply search filter
    var result = searchQuery.isEmpty
        ? habits.toList() // Important: Create a new list instance
        : habits
            .where((habit) =>
                habit.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                habit.description.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
    debugPrint('[HabitsController] _filterAndSortHabits: Count after search filter: ${result.length}');

    // Apply category filter
    if (filterType.value != 'All') {
      result = result
          .where((habit) => habit.category.name == filterType.value)
          .toList();
    }
    debugPrint('[HabitsController] _filterAndSortHabits: Count after category filter: ${result.length}');

    // Apply sorting
    switch (sortType.value) {
      case 'Name':
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Newest':
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Streak':
        // Fix streak sorting: compare the .value of the RxInt
        result.sort((a, b) => b.streakCount.value.compareTo(a.streakCount.value)); 
        break;
      default: // Default (Pinned First)
        result.sort((a, b) {
          // Keep using .value for RxBool comparison (correct)
          final aPinned = a.isPinned.value; 
          final bPinned = b.isPinned.value; 
          if (aPinned && !bPinned) return -1;
          if (!aPinned && bPinned) return 1;
          return a.name.compareTo(b.name);
        });
    }
    debugPrint('[HabitsController] _filterAndSortHabits: Count after sorting: ${result.length}');

    filteredHabits.value = result;
    debugPrint('[HabitsController] _filterAndSortHabits: END - Updated filteredHabits with ${filteredHabits.length} items.');
  }

  // DEBUG Method: Print completion stats for habit
  Future<void> printCompletionStats(int userId) async {
    try {
      final isar = Get.find<Isar>();
      
      // Get all habits
      final habits = await isar.habits
          .filter()
          .user((q) => q.idEqualTo(userId))
          .findAll();
      
      // Get today's habit completions
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final completions = await isar.habitCompletions
          .filter()
          .user((q) => q.idEqualTo(userId))
          .findAll();
      
      final todayCompletions = completions
          .where((c) => 
            DateTime(c.date.year, c.date.month, c.date.day).isAtSameMomentAs(today))
          .toList();
      
      debugPrint('[HabitsController] COMPLETION STATS:');
      debugPrint('  Total habits for user $userId: ${habits.length}');
      debugPrint('  Total completions for user $userId: ${completions.length}');
      debugPrint('  Today\'s completions (${today.toIso8601String().split('T')[0]}):'
          ' ${todayCompletions.length}');
      
      // Print today's completions
      for (final completion in todayCompletions) {
        // Fix orElse callback to return a proper object
        final habit = habits.firstWhereOrNull((h) => h.id == completion.habitId);
        
        debugPrint('  - Habit ID: ${completion.habitId}, '
            'Name: ${habit?.name ?? 'Unknown'}, '
            'Completed: ${completion.completed}');
      }
      
      // Print habits without completions
      final completedHabitIds = todayCompletions.map((c) => c.habitId).toSet();
      for (final habit in habits) {
        if (!completedHabitIds.contains(habit.id)) {
          debugPrint('  - Habit ID: ${habit.id}, Name: ${habit.name}, '
              'NO COMPLETION RECORD');
        }
      }
      
    } catch (e) {
      debugPrint('[HabitsController] Error printing completion stats: $e');
    }
  }
}
