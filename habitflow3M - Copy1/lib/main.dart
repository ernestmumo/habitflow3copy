import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habitflow/models/achievement.dart';
import 'package:habitflow/models/activity_log.dart';
import 'package:habitflow/models/habit_completion.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/user.dart';
import 'models/habit.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

// Controllers
import 'controllers/login_controller.dart';
import 'controllers/signup_controller.dart';
import 'controllers/user_controller.dart';

// Theme
import 'theme/app_theme.dart';

// Services
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/habits_service.dart';
import 'services/debug_service.dart';
import 'services/profile_service.dart';
import 'services/dashboard_service.dart';
import 'services/calendar_service.dart';
import 'services/event_bus.dart';

import 'controllers/calendar_controller.dart';

import 'tools/isar_debug_dump.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar before any controllers or services that use it
  // (Assumes UserModel is your Isar collection for users)
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    UserModelSchema,
    HabitSchema,
    HabitCompletionSchema,
    AchievementModelSchema,
    ActivityLogModelSchema,
  ], directory: dir.path);
  Get.put<Isar>(isar, permanent: true);

  // Register EventBus for app-wide event communication
  Get.put(EventBus(), permanent: true);

  // Register ApiService FIRST (required by AuthService)
  Get.put(ApiService(), permanent: true);

  // Register AuthService (depends on ApiService)
  Get.put(AuthService(), permanent: true);

  // Register UserController needed by other controllers
  Get.put(UserController(), permanent: true);

  // Register CalendarService globally
  Get.put<CalendarService>(CalendarService(), permanent: true);
  // Register CalendarController globally (depends on UserController)
  Get.put<CalendarController>(CalendarController(), permanent: true);

  // Initialize services in proper order with error handling
  try {
    // Next, initialize the debug service for logging
    final debugService = await Get.put(DebugService(), permanent: true).init();
    debugService.info('HabitFlow app starting...', tag: 'Main');
    debugService.info('Auth service initialized', tag: 'Main');

    // Initialize mock data system
    debugService.info('Initializing mock data system...', tag: 'Main');
    await Get.find<ApiService>().initializeConnection();
    debugService.info(
      'Mock data system ready at ${Get.find<ApiService>().baseUrl}',
      tag: 'Main',
    );

    // Log mock system status
    try {
      final status = await Get.find<ApiService>().get('debug/status');
      debugService.debug('System status: $status', tag: 'Main');
    } catch (e) {
      debugService.warning('Failed to get system status', tag: 'Main');
    }
  } catch (e, stack) {
    // Fallback to print if service initialization fails
    print('❌ Critical error during initialization: $e');
    print(stack);
  }

  // Register all services needed by the app
  try {
    // Habits and related services
    Get.put(HabitsService(), permanent: true);
    Get.put(ProfileService(), permanent: true);
    Get.put(DashboardService(), permanent: true);
    // Get.put(CalendarService(), permanent: true); // Remove duplicate registration
    Get.find<DebugService>().info(
      'All feature services initialized',
      tag: 'Main',
    );

    // Make Auth controllers permanent
    // Get.put(UserController(), permanent: true); // Moved earlier
    Get.put(LoginController(), permanent: true);
    Get.put(SignupController(), permanent: true);
    Get.find<DebugService>().info('Auth controllers initialized', tag: 'Main');
  } catch (e) {
    // Log any errors during service registration
    final debug = Get.find<DebugService>();
    debug.error(
      'Failed to initialize services or controllers',
      tag: 'Main',
      error: e,
    );
  }

  // Launch the app
  try {
    Get.find<DebugService>().info('Launching app UI', tag: 'Main');

    // Run initial data cleanup in the background
    cleanupInvalidData()
        .then((_) {
          print('🧹 Background data cleanup completed');
        })
        .catchError((e) {
          print('❌ Background data cleanup error: $e');
        });

    runApp(const MyApp());
  } catch (e, stack) {
    print('❌ Critical error launching app: $e');
    print(stack);
  }
}

// Helper function to clean up invalid completion records for all users
Future<void> cleanupInvalidData() async {
  try {
    print('🧹 Running data cleanup...');

    // Get all users
    final isar = Get.find<Isar>();
    final users = await isar.userModels.where().findAll();

    if (users.isEmpty) {
      print('No users found, skipping cleanup');
      return;
    }

    // Get calendar service
    final calendarService = Get.find<CalendarService>();

    // Run cleanup for each user
    for (final user in users) {
      print('🧹 Cleaning data for user ${user.id} (${user.name})');
      await calendarService.cleanupInvalidCompletions(user.id);
    }

    print('🧹 Data cleanup completed successfully');
  } catch (e) {
    print('❌ Error during data cleanup: $e');
    // Continue app launch even if cleanup fails
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Log app build
    try {
      final debug = Get.find<DebugService>();
      debug.info('Building main app widget', tag: 'MyApp');
    } catch (_) {}

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      defaultTransition: Transition.fade,
      // Add error handling for uncaught exceptions
      onInit: () {
        FlutterError.onError = (FlutterErrorDetails details) {
          try {
            final debug = Get.find<DebugService>();
            debug.error(
              'Uncaught Flutter error: ${details.exception}',
              tag: 'FlutterError',
              error: details.exception,
              stackTrace: details.stack,
            );
          } catch (_) {
            // Fallback if debug service isn't available
            FlutterError.presentError(details);
          }
        };
      },
      routes: {'/isar-debug': (context) => IsarDebugDumpScreen()},
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(name: '/home', page: () => HomeScreen()),
      ],
    );
  }
}
