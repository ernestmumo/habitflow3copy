import 'package:get/get.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../models/activity_log.dart';
import '../services/profile_service.dart';
import '../services/dashboard_service.dart';
import '../services/event_bus.dart';
import 'user_controller.dart';

class ProfileController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();
  final DashboardService _dashboardService = Get.find<DashboardService>();
  final EventBus _eventBus = Get.find<EventBus>();
  final UserController _userController = Get.find<UserController>();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxString name = ''.obs;
  final RxString email = ''.obs;
  final RxString bio = ''.obs;
  final RxString profileImageUrl = ''.obs;

  final RxInt totalHabits = 0.obs;
  final RxInt currentStreak = 0.obs;
  final RxInt longestStreak = 0.obs;
  final RxDouble weeklyCompletionRate = 0.0.obs;
  final RxDouble monthlyCompletionRate = 0.0.obs;

  final RxList<AchievementModel> achievements = <AchievementModel>[].obs;
  final RxList<ActivityLogModel> activityLogs = <ActivityLogModel>[].obs;
  final RxMap<DateTime, int> weeklyActivity = <DateTime, int>{}.obs;
  final RxList<Map<String, dynamic>> weeklyData = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(_userController.currentUser, (UserModel? loggedInUser) {
      if (loggedInUser != null) {
        print('ProfileController: User changed to ${loggedInUser.id}, loading data...');
        loadAllProfileData();
      } else {
        print('ProfileController: User logged out, clearing data...');
        _clearLocalState();
      }
    });
    if (_userController.isLoggedIn.value) {
      loadAllProfileData();
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
      (eventType, eventData) {
        switch (eventType) {
          case EventType.habitAdded:
          case EventType.habitDeleted:
            _refreshHabitStats();
            break;
          case EventType.habitCompleted:
          case EventType.habitUncompleted:
            _refreshCompletionData();
            break;
          case EventType.habitUpdated:
            _refreshAllStats();
            break;
          default:
            break;
        }
      },
    );
  }

  Future<void> _refreshHabitStats() async {
    await Future.wait([
      _loadStatistics(),
      _loadWeeklyActivity(),
    ]);
  }

  Future<void> _refreshCompletionData() async {
    await Future.wait([
      _loadStatistics(),
      _loadWeeklyActivity(),
    ]);
  }

  Future<void> _refreshAllStats() async {
    await Future.wait([
      _loadStatistics(),
      _loadWeeklyActivity(),
    ]);
  }

  Future<void> loadAllProfileData() async {
    if (_userController.currentUserId == null) {
      print('ProfileController: Cannot load data, user ID is null.');
      return;
    }
    print('ProfileController: Loading all profile data for user ${_userController.currentUserId}');
    await Future.wait([
      _loadUserProfile(),
      _loadStatistics(),
      _loadAchievements(),
      _loadActivityLogs(),
      _loadWeeklyActivity(),
    ]);
  }

  Future<void> _loadUserProfile() async {
    final userId = _userController.currentUserId;
    if (userId == null) return;

    print('ProfileController: Loading user profile for $userId');
    final loadedUser = await _profileService.getUserProfile(userId);
    user.value = loadedUser;
    if (loadedUser != null) {
      name.value = loadedUser.name;
      email.value = loadedUser.email;
      bio.value = loadedUser.bio ?? '';
      profileImageUrl.value = loadedUser.profileImageUrl ?? '';
    }
  }

  Future<void> _loadStatistics() async {
    final userId = _userController.currentUserId;
    if (userId == null) return;

    print('ProfileController: Loading stats for $userId');
    totalHabits.value = await _profileService.getTotalHabits(userId);
    currentStreak.value = await _profileService.getCurrentStreak(userId);
    longestStreak.value = await _profileService.getLongestStreak(userId);
    double weekRaw = await _profileService.getWeeklyCompletionRate(userId);
    double monthRaw = await _profileService.getMonthlyCompletionRate(userId);
    weeklyCompletionRate.value = weekRaw.clamp(0.0, 100.0);
    monthlyCompletionRate.value = monthRaw.clamp(0.0, 100.0);
  }

  Future<void> _loadAchievements() async {
    final userId = _userController.currentUserId;
    if (userId == null) return;

    print('ProfileController: Loading achievements for $userId');
    achievements.value = await _profileService.getAchievements(userId);
  }

  Future<void> _loadActivityLogs() async {
    final userId = _userController.currentUserId;
    if (userId == null) return;

    print('ProfileController: Loading activity logs for $userId');
    activityLogs.value = await _profileService.getActivityLogs(userId);
  }

  Future<void> _loadWeeklyActivity() async {
    final userId = _userController.currentUserId;
    if (userId == null) return;

    print('ProfileController: Loading weekly activity for $userId');
    weeklyActivity.value = await _profileService.getWeeklyActivity(userId);
    try {
      final weekData = await _dashboardService.getWeeklyData(userId);
      print('ProfileController: Loaded ${weekData.length} weekly data items from DashboardService');
      weeklyData.assignAll(weekData);
    } catch (e) {
      print('ProfileController: Error loading weekly data from DashboardService: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? profileImageUrl,
  }) async {
    final userId = _userController.currentUserId;
    if (userId == null) return;

    final currentUserProfile = await _profileService.getUserProfile(userId);
    if (currentUserProfile == null) {
      print("ProfileController: Cannot update profile, user not found.");
      return;
    }

    bool changed = false;
    if (name != null && currentUserProfile.name != name) {
      currentUserProfile.name = name;
      changed = true;
    }
    if (email != null && currentUserProfile.email != email) {
      currentUserProfile.email = email;
      changed = true;
    }
    if (bio != null && currentUserProfile.bio != bio) {
      currentUserProfile.bio = bio;
      changed = true;
    }
    if (profileImageUrl != null && currentUserProfile.profileImageUrl != profileImageUrl) {
      currentUserProfile.profileImageUrl = profileImageUrl;
      changed = true;
    }

    if (changed) {
      print('ProfileController: Updating profile for $userId');
      await _profileService.updateUserProfile(currentUserProfile);
      await _loadUserProfile();
      update();
    } else {
      print('ProfileController: No changes detected in profile update for $userId');
    }
  }

  void _clearLocalState() {
    user.value = null;
    name.value = '';
    email.value = '';
    bio.value = '';
    profileImageUrl.value = '';
    totalHabits.value = 0;
    currentStreak.value = 0;
    longestStreak.value = 0;
    weeklyCompletionRate.value = 0.0;
    monthlyCompletionRate.value = 0.0;
    achievements.clear();
    activityLogs.clear();
    weeklyActivity.clear();
    weeklyData.clear();
  }

  void logout() {
    print('ProfileController: Initiating logout...');
    _userController.clearUser();
    Get.offAllNamed('/login');
  }
}
