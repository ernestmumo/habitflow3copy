import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());

  ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProfileHeader(deviceHeight, deviceWidth),
                    _buildStatsSection(deviceHeight, deviceWidth),
                    _buildSettings(deviceHeight, deviceWidth),
                    SizedBox(height: deviceHeight * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(double deviceHeight, double deviceWidth) {
    return Container(
      height: deviceHeight * 0.25,
      width: deviceWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Banner design elements
          Positioned(
            top: -50,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Profile content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile picture
                Obx(() => Container(
                      width: deviceWidth * 0.22,
                      height: deviceWidth * 0.22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: controller.profileImageUrl.value.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  controller.profileImageUrl.value,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.white,
                      ),
                      child: controller.profileImageUrl.value.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue.shade200,
                            )
                          : null,
                    )),
                SizedBox(height: deviceHeight * 0.015),
                // Name
                Obx(() => Text(
                      controller.name.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )),
                SizedBox(height: 4),
                // Bio
                Obx(() => Text(
                      controller.bio.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    )),
              ],
            ),
          ),
          // Edit button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                _showEditProfileDialog(Get.context!, deviceWidth: deviceWidth, deviceHeight: deviceHeight);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(double deviceHeight, double deviceWidth) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: deviceWidth,
            padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.02),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatItem(
                    icon: Icons.checklist,
                    iconColor: Colors.blue.shade600,
                    value: controller.totalHabits,
                    label: 'Total Habits',
                    deviceWidth: deviceWidth,
                    deviceHeight: deviceHeight,
                  ),
                  SizedBox(width: 24),
                  _buildStatItem(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    value: controller.currentStreak,
                    label: 'Current Streak',
                    deviceWidth: deviceWidth,
                    deviceHeight: deviceHeight,
                  ),
                  SizedBox(width: 24),
                  _buildStatItem(
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                    value: controller.longestStreak,
                    label: 'Longest Streak',
                    deviceWidth: deviceWidth,
                    deviceHeight: deviceHeight,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildWeeklySummary(deviceHeight, deviceWidth),
        ],
      ),
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
    final weekDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Obx(() {
      final weekData = controller.weeklyData;
      
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
                  '${weekData.isNotEmpty && groupIndex < weekData.length ? 
                    weekData[groupIndex]['percentage'].toStringAsFixed(0) : 0}% ${weekData[groupIndex]['isToday'] ? '(Today)' : ''}',
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
                      : _getBarColor((weekData[index]['percentage'] as num).toDouble()),
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

  Color _getBarColor(double percentage) {
    if (percentage >= 80) return Colors.green.shade400;
    if (percentage >= 50) return Colors.blue.shade400;
    if (percentage > 0) return Colors.amber.shade400;
    return Colors.grey.shade300; // For days with no activity
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required RxInt value,
    required String label,
    required double deviceWidth,
    required double deviceHeight,
  }) {
    return Column(
      children: [
        Container(
          width: deviceWidth * 0.12,
          height: deviceWidth * 0.12,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(height: 8),
        Obx(() => Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            )),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSettings(double deviceHeight, double deviceWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: deviceWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    // Navigate to help page
                  },
                ),
                Divider(height: 1),
                _buildSettingsItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  titleColor: Colors.red,
                  onTap: () {
                    controller.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? Colors.blue.shade600),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
              : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, {required double deviceWidth, required double deviceHeight}) {
    final nameController = TextEditingController(text: controller.name.value);
    final bioController = TextEditingController(text: controller.bio.value);

    Get.dialog(
      AlertDialog(
        title: Text('Edit Profile', style: TextStyle(fontSize: deviceWidth * 0.05)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: deviceWidth * 0.1,
                backgroundColor: Colors.blue.shade50,
                child: Icon(
                  Icons.person,
                  size: deviceWidth * 0.1,
                  color: Colors.blue.shade200,
                ),
              ),
              SizedBox(height: deviceHeight * 0.01),
              TextButton(
                onPressed: () {
                  // Add image picker functionality here
                },
                child: Text('Change Photo'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updateProfile(
                name: nameController.text,
                bio: bioController.text,
              );
              Get.back();
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
