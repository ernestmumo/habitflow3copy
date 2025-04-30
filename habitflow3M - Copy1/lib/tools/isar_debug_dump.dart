import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/user.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/achievement.dart';
import '../models/activity_log.dart';

class IsarDebugDumpScreen extends StatelessWidget {
  final Isar isar = Get.find<Isar>();

  IsarDebugDumpScreen({Key? key}) : super(key: key);

  Future<Map<String, List<Map<String, dynamic>>>> fetchAllCollections() async {
    final users = await isar.userModels.where().findAll();
    final habits = await isar.habits.where().findAll();
    final completions = await isar.habitCompletions.where().findAll();
    final achievements = await isar.achievementModels.where().findAll();
    final logs = await isar.activityLogModels.where().findAll();
    return {
      'users': users.map((u) => u.toJson()).toList(),
      'habits': habits.map((h) => h.toJson()).toList(),
      'completions': completions.map((c) => c.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isar Database Debug Dump')),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>> (
        future: fetchAllCollections(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView(
            children: data.entries.map((entry) {
              return ExpansionTile(
                title: Text('${entry.key} (${entry.value.length})'),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entry.value.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(item.toString()),
                      )).toList(),
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
