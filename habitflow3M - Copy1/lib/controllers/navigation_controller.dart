import 'package:get/get.dart';
import 'dashboard_controller.dart';
import 'calendar_controller.dart';
import 'user_controller.dart';
import 'habits_controller.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changePage(int index) async {
    final currentSelectedIndex = selectedIndex.value;
    if (index == currentSelectedIndex) return; // Avoid refreshing if the same tab is tapped

    // First update the index immediately for UI responsiveness
    selectedIndex.value = index;
    
    // ENHANCEMENT: Wait a small delay to ensure any pending saves complete
    await Future.delayed(Duration(milliseconds: 100));
    
    // Refresh relevant controllers when their page is selected
    try {
      final userController = Get.find<UserController>();
      final userId = userController.currentUserId;

      print('[NavigationController] Tab changed to $index (${_getTabName(index)})');
      
      if (userId == null) {
        print('[NavigationController] No user logged in, cannot refresh controllers.');
        return;
      }
      
      if (index == 0) { // Dashboard
        print('[NavigationController] BEFORE Dashboard refresh for user $userId');
        final dashboardController = Get.find<DashboardController>();
        await dashboardController.refreshDashboard(userId); 
        print('[NavigationController] AFTER Dashboard refreshed for user $userId');
      } else if (index == 2) { // Calendar
        print('[NavigationController] BEFORE Calendar refresh for user $userId');
        final calendarController = Get.find<CalendarController>();
        await calendarController.refreshCalendarData(); 
        print('[NavigationController] AFTER Calendar refreshed for user $userId');

        // DEBUG: Log habit completion stats from Isar
        final habits = Get.find<HabitsController>();
        await habits.printCompletionStats(userId);
      }
    } catch (e) {
      print('[NavigationController] Error refreshing controller: $e');
      // Handle potential errors if controllers are not found or methods fail
    }
  }
  
  // Helper to convert index to readable tab name
  String _getTabName(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Habits';
      case 2: return 'Calendar';
      case 3: return 'Profile';
      default: return 'Unknown';
    }
  }
}
