import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/user.dart'; 
import '../services/auth_service.dart';
import '../services/calendar_service.dart';

class UserController extends GetxController {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final AuthService _authService = Get.find<AuthService>();

  // Method to set the current user upon login
  void setUser(UserModel user) {
    currentUser.value = user;
    isLoggedIn.value = true;
    print('UserController: Set user to ${user.id} - ${user.name}'); // Debug log
    update(); // Notify listeners
  }

  // Method to clear user data on logout
  void clearUser() {
    print('UserController: Clearing user'); // Debug log
    currentUser.value = null;
    isLoggedIn.value = false;
    update(); // Notify listeners
  }

  // Getter for easy access to user ID
  Id? get currentUserId {
    final userId = currentUser.value?.id;
    // print('UserController: Accessed currentUserId: $userId'); // Debug log (can be noisy)
    return userId;
  }

  // Getter for user name
  String? get currentUserName => currentUser.value?.name;

  // Enhanced login method that cleans up invalid completion records
  Future<bool> login(String email, String password) async {
    try {
      debugPrint('[UserController] Attempting login: $email');
      
      // Get user data from AuthService (returns Map<String, dynamic>)
      final userData = await _authService.login(email, password);
      
      // Find the existing user in Isar database using the returned ID from API
      final isar = Get.find<Isar>();
      final userId = userData['id'] as int; // Assuming ID is returned as int from API
      final existingUser = await isar.userModels.get(userId);
      
      if (existingUser != null) {
        // Use the existing user from the database
        setUser(existingUser);
        debugPrint('[UserController] Login successful: ${existingUser.id}');
        
        // Run data cleanup after login to fix any invalid completion records
        // This fixes issues with incorrect completion percentages
        try {
          debugPrint('[UserController] Running data cleanup for user ${existingUser.id}');
          final calendarService = Get.find<CalendarService>();
          await calendarService.cleanupInvalidCompletions(existingUser.id);
          debugPrint('[UserController] Data cleanup completed successfully');
        } catch (e) {
          debugPrint('[UserController] Error running data cleanup: $e');
          // Continue with login even if cleanup fails
        }
        
        return true;
      } else {
        debugPrint('[UserController] User not found in local database');
        return false;
      }
    } catch (e) {
      debugPrint('[UserController] Login error: $e');
      return false;
    }
  }
}
