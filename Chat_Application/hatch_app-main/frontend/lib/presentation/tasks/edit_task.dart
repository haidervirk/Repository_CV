import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/models/tasks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class EditTaskScreen extends StatefulWidget {
  final Task initialData;

  const EditTaskScreen({super.key, required this.initialData});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late String description;
  late String assignedToId;
  late String communityId;
  late DateTime dueDate;
  late String status;
  bool _hasChanges = false;
  bool _isAssignedBy = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialData;
    title = task.title;
    description = task.description ?? '';
    assignedToId = task.assignedToId;
    communityId = task.communityId.toString();
    dueDate = task.dueDate;
    status = task.status;
    _checkUserRole();
  }

  void _checkUserRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isAssignedBy = user.uid == widget.initialData.assignedToId;
      });
    }
  }

  Future<void> _selectDueDate() async {
    if (!_isAssignedBy) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryColor,
            surface: AppColors.bottomSheetBgColor,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: AppColors.backgroundColor,
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        dueDate = picked;
        _hasChanges = true;
      });
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved changes. Discard them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirmDeleteTask() async {
    if (!_isAssignedBy) return;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        final response = await http.delete(
          Uri.parse('${dotenv.env['base_url']}/api/task/delete/${widget.initialData.id}/'),
          headers: {
            'Content-Type': 'application/json',
            'uid': user.uid,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            Navigator.pop(context, '_deleted');
          } else {
            throw Exception(data['message'] ?? 'Failed to delete task');
          }
        } else {
          throw Exception('Failed to delete task');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _updateTask() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isAssignedBy) {
      final response = await http.post(
        Uri.parse('${dotenv.env['base_url']}/api/task/update/${widget.initialData.id}/assigned_by/'),
        headers: {
          'Content-Type': 'application/json',
          'uid': user.uid,
        },
        body: jsonEncode({
          'community': communityId,
          'assigned_to': assignedToId,
          'title': title,
          'description': description,
          'status': status.toLowerCase(),
          'due_date': '${dueDate.day}/${dueDate.month}/${dueDate.year}',
        }),
      );

      if (response.statusCode == 200) {
        final updatedTask = Task.fromJson(jsonDecode(response.body));
        Navigator.pop(context, updatedTask);
      }
    } else {
      final response = await http.post(
        Uri.parse('${dotenv.env['base_url']}/api/task/update/${widget.initialData.id}/assigned_to/'),
        headers: {
          'Content-Type': 'application/json',
          'uid': user.uid,
        },
        body: jsonEncode({
          'status': status.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final updatedTask = Task.fromJson(jsonDecode(response.body));
        Navigator.pop(context, updatedTask);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmDiscardChanges,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.bottomSheetBgColor,
          title: const Text('Edit Task'),
          actions: _isAssignedBy
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _confirmDeleteTask,
                    tooltip: 'Delete Task',
                  )
                ]
              : null,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: () => _hasChanges = true,
            child: ListView(
              children: [
                TextFormField(
                  initialValue: title,
                  enabled: _isAssignedBy,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                  onSaved: (val) => title = val ?? '',
                  validator: (val) => val!.isEmpty ? 'Enter a task title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: description,
                  enabled: _isAssignedBy,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onSaved: (val) => description = val ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: assignedToId,
                  enabled: _isAssignedBy,
                  decoration: const InputDecoration(labelText: 'Assigned To ID'),
                  onSaved: (val) => assignedToId = val ?? '',
                ),
                const SizedBox(height: 16),
                ListTile(
                  enabled: _isAssignedBy,
                  title: Text('Due Date: ${dueDate.day}/${dueDate.month}/${dueDate.year}', style: TextStyle(color: _isAssignedBy ? AppColors.textColor : AppColors.textColor.withOpacity(0.5))),
                  trailing: Icon(Icons.calendar_today, color: _isAssignedBy ? AppColors.textColor : AppColors.textColor.withOpacity(0.5)),
                  onTap: _selectDueDate,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: TextStyle(color: AppColors.textColor.withOpacity(0.7), fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Open'),
                          selected: status.toLowerCase() == 'open',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                status = 'open';
                                _hasChanges = true;
                              });
                            }
                          },
                          selectedColor: AppColors.primaryColor,
                          labelStyle: TextStyle(
                            color: status.toLowerCase() == 'open' ? Colors.white : AppColors.textColor,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('In Progress'),
                          selected: status.toLowerCase() == 'in-progress',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                status = 'in-progress';
                                _hasChanges = true;
                              });
                            }
                          },
                          selectedColor: AppColors.primaryColor,
                          labelStyle: TextStyle(
                            color: status.toLowerCase() == 'in-progress' ? Colors.white : AppColors.textColor,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Completed'),
                          selected: status.toLowerCase() == 'completed',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                status = 'completed';
                                _hasChanges = true;
                              });
                            }
                          },
                          selectedColor: AppColors.primaryColor,
                          labelStyle: TextStyle(
                            color: status.toLowerCase() == 'completed' ? Colors.white : AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _updateTask();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Update Task',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
