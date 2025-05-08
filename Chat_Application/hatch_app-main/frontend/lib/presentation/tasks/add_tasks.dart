import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/community.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  int? selectedCommunityId;
  String? selectedAssignee;
  String taskTitle = '';
  String description = '';
  DateTime? dueDate;

  bool _isLoadingCommunities = false;
  bool _isLoadingMembers = false;
  bool _isSubmitting = false;
  String? _communitiesError;
  String? _membersError;

  List<Community> communities = [];
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    setState(() {
      _isLoadingCommunities = true;
      _communitiesError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/chat/direct-messages/communities/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'uid': user.uid,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> bucketList = json.decode(response.body);

        final filteredBuckets = bucketList.where((bucket) => bucket['Bucket Name'] != 'Direct Messages').toList();

        setState(() {
          communities = filteredBuckets.map((bucket) {
            final List<dynamic> channels = bucket['channels_list'];
            return Community(
              id: bucket['Bucket ID'],
              name: bucket['Bucket Name'],
              members: '${bucket['Member Count']} members',
              avatarUrl: bucket['Bucket Picture'] ?? 'https://via.placeholder.com/150',
              subGroups: channels
                  .map((channel) => SubGroup(
                        id: channel['channel_id'],
                        tag: channel['channel_name'],
                        message: channel['latest_message'] ?? '',
                        time: channel['timestamp'] ?? DateTime.now().toString(),
                      ))
                  .toList(),
            );
          }).toList();

          if (communities.isNotEmpty) {
            selectedCommunityId = communities[0].id;
            _fetchMembers();
          }
        });
      } else if (response.statusCode == 403) {
        throw Exception('User not authenticated');
      } else {
        throw Exception('Failed to load communities');
      }
    } catch (e) {
      setState(() {
        _communitiesError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingCommunities = false;
      });
    }
  }

  Future<void> _fetchMembers() async {
    if (selectedCommunityId == null) return;

    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
      members.clear();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/chat/buckets/$selectedCommunityId/members/'),
        headers: {
          'uid': user.uid,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> membersList = json.decode(response.body);
        setState(() {
          members = membersList
              .map((member) => {
                    "uid": member['user']['id'],
                    "name": member['user']['name'],
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load members');
      }
    } catch (e) {
      setState(() {
        _membersError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryColor,
              surface: AppColors.bottomSheetBgColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.backgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate() || selectedCommunityId == null || selectedAssignee == null || dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print(selectedAssignee);

      final response = await http
          .post(
            Uri.parse('${dotenv.env['base_url']}/api/task/create/'),
            headers: {
              'uid': user.uid,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'community': selectedCommunityId, 'assigned_to': selectedAssignee, 'title': taskTitle, 'description': description, 'due_date': '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to create task');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Add New Task'),
        backgroundColor: AppColors.bottomSheetBgColor,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCommunityId?.toString(),
                      dropdownColor: AppColors.bottomSheetBgColor,
                      decoration: InputDecoration(
                        labelText: 'Select Community',
                        labelStyle: TextStyle(color: AppColors.lightTextColor),
                        border: const OutlineInputBorder(),
                      ),
                      items: _isLoadingCommunities
                          ? [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: CircularProgressIndicator(),
                              )
                            ]
                          : _communitiesError != null
                              ? [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Text(_communitiesError!, style: TextStyle(color: Colors.red)),
                                        TextButton(
                                          onPressed: _fetchCommunities,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                ]
                              : communities
                                  .map((c) => DropdownMenuItem<String>(
                                        value: c.id.toString(),
                                        child: Text(c.name),
                                      ))
                                  .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCommunityId = int.parse(val!);
                          selectedAssignee = null;
                          members.clear();
                        });
                        _fetchMembers();
                      },
                      validator: (value) => value == null ? 'Select a community' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedAssignee,
                      dropdownColor: AppColors.bottomSheetBgColor,
                      decoration: InputDecoration(
                        labelText: 'Assign To',
                        labelStyle: TextStyle(color: AppColors.lightTextColor),
                        border: const OutlineInputBorder(),
                      ),
                      items: _isLoadingMembers
                          ? [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: CircularProgressIndicator(),
                              )
                            ]
                          : _membersError != null
                              ? [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Text(_membersError!, style: TextStyle(color: Colors.red)),
                                        TextButton(
                                          onPressed: _fetchMembers,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                ]
                              : members
                                  .map((m) => DropdownMenuItem<String>(
                                        value: m['uid'],
                                        child: Text(m['name']),
                                      ))
                                  .toList(),
                      onChanged: (val) => setState(() => selectedAssignee = val),
                      validator: (value) => value == null ? 'Select an assignee' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        labelStyle: TextStyle(color: AppColors.lightTextColor),
                        border: const OutlineInputBorder(),
                      ),
                      style: TextStyle(color: AppColors.textColor),
                      validator: (value) => value!.isEmpty ? 'Enter task title' : null,
                      onSaved: (value) => taskTitle = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: AppColors.lightTextColor),
                        border: const OutlineInputBorder(),
                      ),
                      style: TextStyle(color: AppColors.textColor),
                      validator: (value) => value!.isEmpty ? 'Enter description' : null,
                      onSaved: (value) => description = value!,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        dueDate == null ? 'Pick Due Date' : 'Due Date: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                        style: TextStyle(color: AppColors.textColor),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.calendar_today, color: AppColors.textColor),
                        onPressed: _pickDueDate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Create Task'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
