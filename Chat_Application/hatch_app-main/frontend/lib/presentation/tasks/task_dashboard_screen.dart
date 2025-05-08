import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/presentation/notification/notifications_list.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/presentation/tasks/add_tasks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/presentation/notification/notifications_list.dart';
import 'package:frontend/presentation/tasks/add_tasks.dart';
import 'package:frontend/presentation/tasks/task_details_screen.dart';
import 'package:frontend/presentation/chats/widgets.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> notifications = [];
  Map<String, List<Map<String, dynamic>>> taskGroups = {};
  Map<String, int> dailyTaskCounts = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchNotifications();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/task/fetch_notifications'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/task/get_all_tasks/'),
        headers: {'uid': user.uid},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        taskGroups = {};
        for (var community in data['communities']) {
          final communityName = community['community_name'];
          final tasks = community['tasks'];
          taskGroups[communityName] = List<Map<String, dynamic>>.from(
            tasks.map((task) => {
                  'label': task['title'],
                  'isComplete': task['status'] == 'completed',
                  'dueDate': task['due_date'],
                  'task_id': task['task_id'],
                }),
          );
        }

        dailyTaskCounts = Map<String, int>.from(data['overall_stats']['daily_task_counts']);
      } else {
        throw Exception('Failed to load tasks.');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTaskGroup(String title, List<Map<String, dynamic>> tasks) {
    final filtered = _searchQuery.isEmpty ? tasks : tasks.where((task) => task['label'].toLowerCase().contains(_searchQuery)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.textColor,
              child: Icon(Icons.groups, color: AppColors.backgroundColor),
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bottomSheetBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _searchQuery.isEmpty ? 'No tasks in this group yet' : 'No matching tasks found',
                style: TextStyle(color: AppColors.lightTextColor),
              ),
            ),
          )
        else
          ...filtered.map((task) => _buildTask(task['label'], task['isComplete'], task['task_id'])),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTask(String label, bool isComplete, int taskId) {
    final statusColor = isComplete ? Colors.green : AppColors.errorColor;
    final textColor = isComplete ? AppColors.lightTextColor : AppColors.textColor;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailsScreen(taskId: taskId),
          ),
        ).then((_) => _fetchDashboardData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isComplete ? AppColors.bottomSheetBgColor : AppColors.secondaryColor.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.more_vert, size: 16, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isComplete ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            Icon(
              isComplete ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphCard() {
    final dates = dailyTaskCounts.keys.toList();
    final counts = dailyTaskCounts.values.toList();
    if (dates.isEmpty) {
      return Container(
        height: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bottomSheetBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No activity data yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bottomSheetBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index >= 0 && index < dates.length) {
                    final date = DateTime.parse(dates[index]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(
                          color: AppColors.lightTextColor,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          minX: 0,
          maxX: dates.length.toDouble() - 1,
          minY: 0,
          maxY: counts.reduce((a, b) => a > b ? a : b).toDouble(),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              color: AppColors.primaryColor,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryColor.withOpacity(0.3),
              ),
              spots: List.generate(
                dates.length,
                (index) => FlSpot(index.toDouble(), counts[index].toDouble()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = "${now.day} ${_monthName(now.month)}, ${now.year}";

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Good morning!", style: TextStyle(fontSize: 14, color: AppColors.lightTextColor)),
                    const SizedBox(height: 4),
                    Text(formattedDate, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textColor)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _notificationsEnabled ? Icons.notifications_none : Icons.notifications_off_outlined,
                  color: AppColors.textColor,
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListScreen())),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildGraphCard(),
                  const SizedBox(height: 12),
                  Divider(color: AppColors.lightTextColor.withOpacity(0.4), thickness: 0.5),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: TextStyle(color: AppColors.lightTextColor),
                      prefixIcon: Icon(Icons.search, color: AppColors.lightTextColor),
                      filled: true,
                      fillColor: AppColors.bottomSheetBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var entry in taskGroups.entries) _buildTaskGroup(entry.key, entry.value),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          ).then((_) => _fetchDashboardData());
        },
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.add, color: AppColors.textColor),
      ),
    );
  }
}
