import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user.dart';

part 'activity_log.g.dart';

@Collection()
class ActivityLogModel {
  Id id = Isar.autoIncrement;
  
  // Link to the user associated with this log
  final user = IsarLink<UserModel>();
  
  late String description;
  late DateTime timestamp;
  late int iconCodePoint;
  late String iconFontFamily;

  ActivityLogModel();

  ActivityLogModel.create({
    required this.description,
    required this.timestamp,
    required IconData icon,
  })  : iconCodePoint = icon.codePoint,
        iconFontFamily = icon.fontFamily ?? '';

  @Ignore()
  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'iconCodePoint': iconCodePoint,
    'iconFontFamily': iconFontFamily,
  };
}
