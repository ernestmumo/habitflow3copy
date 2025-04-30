import 'package:isar/isar.dart';
import 'user.dart'; // Import the UserModel

part 'habit_completion.g.dart';

@collection
class HabitCompletion {
  Id id = Isar.autoIncrement;
  
  // Link to the user who completed this habit
  final user = IsarLink<UserModel>(); 

  late int habitId; // Keep this if you still need direct habit reference by ID
  // Alternatively, could use: final habit = IsarLink<Habit>();
  late DateTime date;
  bool completed = true;

  Map<String, dynamic> toJson() => {
    'id': id,
    // userId is implicitly handled by the IsarLink
    'habitId': habitId,
    'date': date.toIso8601String(),
    'completed': completed,
  };
}
