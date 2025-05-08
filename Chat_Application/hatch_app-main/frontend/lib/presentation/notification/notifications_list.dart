import 'package:flutter/material.dart';
import 'package:frontend/presentation/tasks/task_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class NotificationModel {
  final int id;
  final int? taskId;
  final String? taskTitle;
  final String message;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.message,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      taskId: json['task_id'],
      taskTitle: json['task_title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/task/fetch_notifications'),
        headers: {
          'Content-Type': 'application/json',
          'uid': FirebaseAuth.instance.currentUser!.uid,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime.toLocal());
  }

  Color _getNotificationColor(String message) {
    if (message.toLowerCase().contains('updated')) {
      return Colors.yellow.withOpacity(0.2);
    } else if (message.toLowerCase().contains('deleted')) {
      return Colors.red.withOpacity(0.2);
    }
    return AppColors.bottomSheetBgColor;
  }

  Color _getNotificationIconColor(String message) {
    if (message.toLowerCase().contains('updated')) {
      return Colors.yellow;
    } else if (message.toLowerCase().contains('deleted')) {
      return Colors.red;
    }
    return AppColors.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
          title: Text(
            'Task Notifications',
            style: TextStyle(color: AppColors.textColor),
          ),
          backgroundColor: AppColors.bottomSheetBgColor,
          automaticallyImplyLeading: true,
          iconTheme: IconThemeData(color: AppColors.textColor)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(
                    'Error: $error',
                    style: TextStyle(color: AppColors.errorColor),
                  ),
                )
              : notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 48,
                            color: AppColors.lighterTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: AppColors.lightTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: AppColors.bottomSheetBgColor,
                        ),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.bottomSheetBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications,
                                  color: _getNotificationIconColor(notification.message),
                                ),
                              ),
                              title: Text(
                                notification.message,
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(notification.createdAt),
                                style: TextStyle(
                                  color: AppColors.lightTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: notification.taskId != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '#${notification.taskId}',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                // Navigate to task details
                                if (notification.taskId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskDetailsScreen(taskId: notification.taskId!),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
