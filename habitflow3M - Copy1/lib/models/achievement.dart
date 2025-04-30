import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'user.dart';

part 'achievement.g.dart';

@Collection()
class AchievementModel {
  Id id = Isar.autoIncrement;
  
  // Link to the user who earned this achievement
  final user = IsarLink<UserModel>();
  
  late String title;
  late String description;
  late int iconCodePoint;
  late String iconFontFamily;
  late DateTime earnedAt;

  AchievementModel();

  AchievementModel.create({
    required this.title,
    required this.description,
    required IconData icon,
    required this.earnedAt,
  })  : iconCodePoint = icon.codePoint,
        iconFontFamily = icon.fontFamily ?? '';

  @Ignore()
  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconCodePoint': iconCodePoint,
    'iconFontFamily': iconFontFamily,
    'earnedAt': earnedAt.toIso8601String(),
  };
}
