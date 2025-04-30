# HabitFlow App Documentation

HabitFlow is a robust, user-centric habit tracking application built with Flutter and Dart. The architecture is modular, scalable, and designed for clear data isolation between users. This document provides a detailed overview of the codebase, describing the function and relevance of every file in the core directories: `lib/`, `lib/screens/`, `lib/models/`, `lib/controllers/`, and `lib/services`.

---

## lib/

- **main.dart**  
  The entry point of the app. It initializes Flutter bindings, sets up dependency injection with GetX, connects to the Isar database, and launches the main app widget. It also registers all controllers and services and runs a data cleanup routine to ensure data integrity on startup.

- **theme/**  
  - `app_theme.dart`  
    Defines the color palette, text styles, and theming logic for the app, ensuring a consistent and visually appealing user interface.

- **tools/**  
  - `isar_debug_dump.dart`  
    Utility for exporting or debugging the Isar database. Useful for development and troubleshooting data-related issues.

---

## lib/models/

These files define the data structures used throughout the app. Each model represents a core entity in the habit tracking domain.

- **achievement.dart**  
  Defines the `AchievementModel`, representing user achievements, their properties, and serialization logic.
- **achievement.g.dart**  
  Generated code for Isar serialization of achievements.
- **activity_log.dart**  
  Contains the `ActivityLogModel`, which tracks significant user actions for analytics or audit purposes.
- **activity_log.g.dart**  
  Generated code for Isar serialization of activity logs.
- **habit.dart**  
  The primary model for user habits, including fields like name, frequency, and user association.
- **habit.g.dart**  
  Generated Isar serialization code for habits.
- **habit_completion.dart**  
  Represents a record of a habit being completed on a specific date by a user.
- **habit_completion.g.dart**  
  Generated code for Isar serialization of habit completions.
- **user.dart**  
  Defines the `UserModel`, which stores user profile information and authentication data.
- **user.g.dart**  
  Generated Isar serialization code for users.

---

## lib/screens/

Screens are the UI pages that users interact with. Each screen is responsible for rendering a specific part of the app's functionality.

- **calendar_screen.dart**  
  Displays a calendar view of habit completions, allowing users to see their progress over time. Integrates with the CalendarController for data and interaction.
- **dashboard_screen.dart**  
  The main overview screen, showing weekly completion charts, today’s habits, and summary statistics. Relies on DashboardController and DashboardService for data.
- **habits_screen.dart**  
  The core screen for managing habits. Users can view, add, edit, or delete habits. Observes the HabitsController for real-time updates.
- **home_screen.dart**  
  The root navigation widget, orchestrating tab switching and routing between main sections (Dashboard, Habits, Calendar, Profile).
- **login_screen.dart**  
  UI for user authentication. Allows users to log in with email and password, and handles error messages and loading states.
- **profile_screen.dart**  
  Displays user profile details, weekly overview charts, and statistics. Pulls data from ProfileController and DashboardService to ensure consistency.
- **signup_screen.dart**  
  UI for new user registration. Collects user details, validates input, and communicates with AuthService for account creation.

---

## lib/controllers/

Controllers are the backbone of state management in HabitFlow. They coordinate between the UI and the underlying services, ensuring data flows reactively and securely.

- **calendar_controller.dart**  
  Manages the state and logic for the calendar screen. Handles loading, filtering, and updating completion data for the current user.
- **dashboard_controller.dart**  
  Oversees the dashboard’s state, including weekly statistics, today’s habits, and completion rates. Ensures the dashboard is always up-to-date.
- **habits_controller.dart**  
  Central controller for all habit operations. Loads, filters, and syncs habits for the logged-in user. Also includes debugging utilities for data integrity.
- **login_controller.dart**  
  Handles the login process, form validation, and error reporting. Communicates with AuthService to authenticate users.
- **navigation_controller.dart**  
  Orchestrates tab navigation and ensures that switching between screens triggers the appropriate data refreshes.
- **profile_controller.dart**  
  Manages profile data, including fetching and updating user stats, and synchronizing weekly overview data with the dashboard.
- **signup_controller.dart**  
  Handles user registration logic, including form validation and error handling, and communicates with AuthService.
- **theme_controller.dart**  
  Manages the app’s theme state, allowing for dynamic switching between light and dark modes.
- **user_controller.dart**  
  Maintains the current user’s session, authentication state, and user-specific data. Also runs data cleanup after login to ensure statistics are correct.

---

## lib/services/

Services encapsulate business logic, data access, and communication with external systems or APIs.

- **api_service.dart**  
  Handles all HTTP requests to the backend or mock API. Provides methods for GET, POST, and other network operations. Used by AuthService and other services.
- **auth_service.dart**  
  Manages user authentication, including login and registration. Communicates with the backend via ApiService and returns user data.
- **calendar_service.dart**  
  Manages habit completion data, including adding, removing, and cleaning up completion records. Ensures all completion data is valid and user-specific.
- **dashboard_service.dart**  
  Calculates and provides statistics for the dashboard and profile screens, such as weekly completion rates and today’s progress. Ensures data isolation by filtering by user.
- **debug_service.dart**  
  Provides logging, debugging, and diagnostic utilities throughout the app. Used for both development and production troubleshooting.
- **event_bus.dart**  
  Implements a simple event bus for app-wide communication between components, supporting decoupled event-driven architecture.
- **habits_service.dart**  
  Handles CRUD operations for habits in the Isar database. Ensures all operations are filtered by user and maintains data integrity.
- **profile_service.dart**  
  Manages user profile data, including fetching and updating user information and statistics.

---

## Data Flow and Architecture

HabitFlow uses the GetX package for dependency injection and state management, ensuring a reactive UI and clean separation of concerns. The Isar database provides fast, local persistence for all user, habit, and completion data. All CRUD operations and statistics calculations are strictly filtered by user ID, guaranteeing robust data isolation and privacy.

Controllers observe changes in the database and update the UI in real time. Services encapsulate all business logic, keeping controllers lean and focused on state management. Models define the schema for all persisted data, and screens render the user interface, responding to changes from their respective controllers.

---

## Conclusion

This modular architecture ensures that HabitFlow is maintainable, scalable, and secure. Each file in the codebase serves a specific role, contributing to a seamless and robust habit tracking experience for every user. For developers, this documentation should provide a clear roadmap for understanding, extending, or debugging the application.
