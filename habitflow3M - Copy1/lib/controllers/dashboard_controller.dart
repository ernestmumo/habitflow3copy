import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/habit.dart';
import '../models/user.dart';
import '../services/dashboard_service.dart';
import '../services/event_bus.dart';
import 'user_controller.dart';

class DashboardController extends GetxController {
  final DashboardService dashboardService = Get.find<DashboardService>();
  final EventBus _eventBus = Get.find<EventBus>();
  final UserController _userController = Get.find<UserController>();

  final RxString greeting = ''.obs;
  final RxInt habitsForToday = 0.obs;
  final RxInt completedHabits = 0.obs;
  final RxDouble completionRate = 0.0.obs;
  final RxList<Habit> todaysHabits = <Habit>[].obs;
  final RxString motivationQuote = 'Consistency is the key to success!'.obs;
  final RxInt currentStreak = 0.obs;
  final RxInt longestStreak = 0.obs;
  final RxList<Map<String, dynamic>> weeklyData = <Map<String, dynamic>>[].obs;
  final RxList<Habit> reminders = <Habit>[].obs;

  @override
  void onInit() {
    super.onInit();
    _setupEventListeners();
    
    ever(_userController.currentUser, (UserModel? user) {
      if (user != null) {
        print('[DashboardController] User changed: ${user.id}. Refreshing dashboard.');
        refreshDashboard(user.id);
      } else {
        print('[DashboardController] User logged out. Clearing dashboard.');
        _clearDashboardData();
      }
    });

    final initialUser = _userController.currentUser.value;
    if (initialUser != null) {
      refreshDashboard(initialUser.id);
    }
  }
  
  void _clearDashboardData() {
    greeting.value = '';
    habitsForToday.value = 0;
    completedHabits.value = 0;
    completionRate.value = 0.0;
    todaysHabits.clear();
    motivationQuote.value = 'Consistency is the key to success!'; 
    currentStreak.value = 0;
    longestStreak.value = 0;
    weeklyData.clear();
    reminders.clear();
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
        switch (eventType) {
          case EventType.habitCompleted:
          case EventType.habitUncompleted:
            final userId = _userController.currentUserId;
            if (userId != null) _refreshTodayStats(userId);
            break;
          case EventType.habitAdded:
          case EventType.habitDeleted:
          case EventType.habitUpdated:
            final userId = _userController.currentUserId;
            if (userId != null) refreshDashboard(userId);
            break;
          default:
            break;
        }
      },
    );
  }

  Future<void> refreshDashboard(Id userId) async {
    print('[DashboardController] Refreshing dashboard for user $userId');
    try {
      await Future.wait([
        _setGreeting(userId),
        _loadHabits(userId),
        _calculateStats(userId),
        _loadWeeklyData(userId),
        _loadStreaks(userId),
        _loadReminders(userId),
      ]);
    } catch (e) {
      print('[DashboardController] Error refreshing dashboard: $e');
    }
  }

  Future<void> _setGreeting(Id userId) async {
    greeting.value = await dashboardService.getGreeting(userId);
  }

  Future<void> _loadHabits(Id userId) async {
    final habits = await dashboardService.getTodaysHabits(userId);
    todaysHabits.assignAll(habits);
    habitsForToday.value = habits.length;
  }

  Future<void> _calculateStats(Id userId) async {
    final stats = await dashboardService.getTodayStats(userId);
    completedHabits.value = stats['completedHabits'] ?? 0;
    double rawCompletion = stats['completionRate'] ?? 0.0;
    completionRate.value = rawCompletion.clamp(0.0, 100.0);
  }

  Future<void> _loadWeeklyData(Id userId) async {
    final data = await dashboardService.getWeeklyData(userId);
    weeklyData.assignAll(data.map((e) {
      e['percentage'] = (e['percentage'] as num).clamp(0, 100);
      return e;
    }).toList());
  }

  Future<void> _loadStreaks(Id userId) async {
    final streaks = await dashboardService.getStreaks(userId);
    currentStreak.value = streaks['currentStreak'] ?? 0;
    longestStreak.value = streaks['longestStreak'] ?? 0;
  }

  Future<void> _loadReminders(Id userId) async {
    final r = await dashboardService.getReminders(userId);
    reminders.assignAll(r);
  }

  Future<void> _refreshTodayStats(Id userId) async {
    print('[DashboardController] Refreshing today stats for user $userId');
    try {
      await Future.wait([
        _loadHabits(userId),
        _calculateStats(userId),
        _loadWeeklyData(userId),
        _loadStreaks(userId),
      ]);
    } catch (e) {
      print('[DashboardController] Error refreshing today stats: $e');
    }
  }
}
