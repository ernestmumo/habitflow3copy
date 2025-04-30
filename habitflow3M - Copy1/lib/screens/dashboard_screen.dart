import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/user_controller.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController());
  final UserController userController = Get.find<UserController>();

  DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = userController.currentUserId;
          if (userId != null) {
            await controller.refreshDashboard(userId);
          } else {
            print("[DashboardScreen] No user logged in, cannot refresh.");
            // Optionally show a message or handle the no-user case
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: deviceHeight * 0.02),
                  // Welcome banner
                  _buildWelcomeBanner(deviceHeight),
                  SizedBox(height: deviceHeight * 0.02),
                  // Today's habits card
                  _buildTodaysHabitsCard(deviceHeight, deviceWidth),
                  SizedBox(height: deviceHeight * 0.02),
                  // Progress overview
                  _buildProgressOverview(deviceHeight, deviceWidth),
                  SizedBox(height: deviceHeight * 0.02),
                  // Weekly summary
                  _buildWeeklySummary(deviceHeight, deviceWidth),
                  SizedBox(height: deviceHeight * 0.02),
                  // Inspirational corner
                  _buildInspirationalCorner(deviceHeight),
                  SizedBox(height: deviceHeight * 0.02),
                  // Upcoming reminders
                  _buildUpcomingReminders(deviceHeight),
                  SizedBox(height: deviceHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(double deviceHeight) {
    return Obx(() => Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.greeting}, John',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8), // Add some spacing between the columns
          Flexible(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Reduced horizontal padding
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${controller.habitsForToday.value} habits today',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13, // Slightly smaller font size
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${controller.completionRate.value.clamp(0, 100).toStringAsFixed(0)}% complete',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11, // Slightly smaller font size
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day} ${now.month} ${now.year}';
  }

  Widget _buildTodaysHabitsCard(double deviceHeight, double deviceWidth) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Habits",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.completedHabits}/${controller.habitsForToday.value}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            controller.todaysHabits.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No habits for today',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: controller.todaysHabits.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final habit = controller.todaysHabits[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(habit.categoryColor).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category,
                            color: Color(habit.categoryColor),
                          ),
                        ),
                        title: Text(
                          habit.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: habit.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: habit.isDone
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          habit.description ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Checkbox(
                          activeColor: Colors.blue.shade600,
                          value: habit.isDone,
                          onChanged: null, // TODO: Implement completion toggle with Isar if needed
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview(double deviceHeight, double deviceWidth) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Progress & Streaks",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 20),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakIndicator(
                  title: "Current Streak",
                  value: controller.currentStreak.value.toString(),
                  subtitle: "days",
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                _buildStreakIndicator(
                  title: "Longest Streak",
                  value: controller.longestStreak.value.toString(),
                  subtitle: "days",
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                ),
                _buildStreakIndicator(
                  title: "Completion Rate",
                  value: controller.completionRate.value.clamp(0, 100).toStringAsFixed(0) + "%",
                  subtitle: "this week",
                  icon: Icons.insert_chart,
                  color: Colors.green,
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIndicator({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummary(double deviceHeight, double deviceWidth) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Weekly Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 180,
              child: _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final weekData = controller.weeklyData; // already reactive, but wrap BarChart in Obx for UI updates
    final weekDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Obx(() {
      if (weekData.isEmpty) {
        return Center(child: Text("No data available"));
      }
      
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${weekData[groupIndex]['percentage'].toStringAsFixed(0)}% ${weekData[groupIndex]['isToday'] ? '(Today)' : ''}',
                  TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= weekData.length) return const SizedBox.shrink();
                  
                  // Use the weekday property from the data instead of just the index
                  final int weekdayIndex = weekData[index]['weekday'] as int;
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      weekDayLabels[weekdayIndex],
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: weekData[index]['isToday'] ? FontWeight.bold : FontWeight.w500,
                        color: weekData[index]['isToday'] ? Colors.blue.shade800 : null,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 25 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${value.toInt()}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
                reservedSize: 35,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (value) {
              if (value % 25 != 0) return FlLine(color: Colors.transparent);
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5],
              );
            },
            drawVerticalLine: false,
          ),
          barGroups: List.generate(weekData.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (weekData[index]['percentage'] as num).clamp(0, 100).toDouble(),
                  color: weekData[index]['isToday'] 
                      ? Colors.blue.shade700
                      : _getBarColor(weekData[index]['percentage']),
                  width: 20,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  Color _getBarColor(dynamic percentage) {
    // Convert to double to ensure type safety
    final double value = (percentage is int) ? percentage.toDouble() : (percentage as double);
    
    if (value >= 80) return Colors.green;
    if (value >= 50) return Colors.amber;
    return Colors.redAccent;
  }

  Widget _buildInspirationalCorner(double deviceHeight) {
    return Obx(() => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                ),
                SizedBox(width: 8),
                Text(
                  "Daily Inspiration",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              controller.motivationQuote.value,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Keep up the good work! You're just a few days away from beating your longest streak.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildUpcomingReminders(double deviceHeight) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  "Upcoming Reminders",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
            SizedBox(height: 16),
            Obx(() {
              if (controller.reminders.isEmpty) {
                return Center(
                  child: Text(
                    "No upcoming reminders",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.reminders.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final habit = controller.reminders[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      habit.name,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      habit.reminder ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
