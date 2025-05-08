import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChannelDetailsScreen extends StatefulWidget {
  final int channelId;

  const ChannelDetailsScreen({
    super.key,
    required this.channelId,
  });

  @override
  State<ChannelDetailsScreen> createState() => _ChannelDetailsScreenState();
}

class _ChannelDetailsScreenState extends State<ChannelDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  String? _channelName;
  String? _channelPicture;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadChannelDetails();
  }

  Future<void> _loadChannelDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/chat/channels/${widget.channelId}/settings'),
        headers: {
          'uid': user.uid,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _channelName = data['channel_name'];
          _channelPicture = data['channel_picture'];
          _members = List<Map<String, dynamic>>.from(
            data['members'].map((m) => {
                  'name': m['member_name'].toString(),
                  'id': m['member_id'].toString(),
                  'role': m['bucket_role'].toString(),
                }),
          );
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load channel details');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addMembers() async {
    final controller = TextEditingController();

    final emails = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Members'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter email addresses (comma separated)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () {
              final emailList = controller.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              Navigator.pop(context, emailList);
            },
          ),
        ],
      ),
    );

    if (emails != null && emails.isNotEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final response = await http.post(
          Uri.parse('${dotenv.env['base_url']}/api/chat/channels/${widget.channelId}/members/add/'),
          headers: {
            'uid': user.uid,
            'Content-Type': 'application/json',
          },
          body: json.encode({'new': emails}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
          _loadChannelDetails();
        } else {
          throw Exception('Failed to add members');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding members: $e')),
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _updateMemberRole(String memberId, String currentRole) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['member', 'admin'].map((role) {
            return ListTile(
              title: Text(role),
              selected: role == currentRole,
              onTap: () => Navigator.pop(context, role),
            );
          }).toList(),
        ),
      ),
    );

    if (newRole != null && newRole != currentRole) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final response = await http.post(
          Uri.parse('${dotenv.env['base_url']}/api/chat/channels/${widget.channelId}/members/$memberId/role/'),
          headers: {
            'uid': user.uid,
            'Content-Type': 'application/json',
          },
          body: json.encode({'status': newRole}),
        );

        if (response.statusCode == 200) {
          setState(() {
            final memberIndex = _members.indexWhere((m) => m['id'] == memberId);
            if (memberIndex != -1) {
              _members[memberIndex]['role'] = newRole;
            }
          });
        } else {
          throw Exception('Failed to update role');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    final currentUserMember = _members.firstWhere(
      (m) => m['id'] == FirebaseAuth.instance.currentUser?.uid,
      orElse: () => {'role': 'member'},
    );
    final isAdmin = currentUserMember['role'] == 'admin';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Channel Info',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_channelPicture ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _channelName ?? '',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: _addMembers,
                  icon: Icon(Icons.add, color: AppColors.primaryColor),
                  tooltip: 'Add members',
                ),
            ],
          ),
          const SizedBox(height: 10),
          ..._members.map((member) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bottomSheetBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      member['name']!,
                      style: TextStyle(color: AppColors.textColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: member['role'] == 'admin' ? AppColors.primaryColor : AppColors.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      member['role']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textColorInvert,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
