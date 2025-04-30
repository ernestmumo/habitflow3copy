import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'user.dart';

part 'habit.g.dart';

@collection
class Habit {
  Id id = Isar.autoIncrement;

  // Link to the user who owns this habit
  final user = IsarLink<UserModel>();

  late String name;
  String? description;
  late String categoryName;
  int categoryColor = 0xFF2196F3; // Default blue
  int categoryIconCodePoint = Icons.checklist.codePoint;
  String? categoryIconFontFamily = Icons.checklist.fontFamily;
  DateTime createdAt = DateTime.now();
  int streakCount = 0;
  int longestStreak = 0;
  bool isPinned = false;
  bool isDone = false;
  List<DateTime> completedDates = [];
  String? reminder;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'categoryName': categoryName,
    'categoryColor': categoryColor,
    'categoryIconCodePoint': categoryIconCodePoint,
    'categoryIconFontFamily': categoryIconFontFamily,
    'createdAt': createdAt.toIso8601String(),
    'streakCount': streakCount,
    'longestStreak': longestStreak,
    'isPinned': isPinned,
    'isDone': isDone,
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    'reminder': reminder,
  };
}
