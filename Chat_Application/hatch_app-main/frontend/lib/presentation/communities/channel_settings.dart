import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChannelSettingsScreen extends StatefulWidget {
  final String channelId;
  final String bucketId;

  const ChannelSettingsScreen({
    super.key,
    required this.channelId,
    required this.bucketId,
  });

  @override
  State<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends State<ChannelSettingsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _channelDetails;
  List<dynamic> _members = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadChannelDetails();
    _loadMembers();
  }

  Future<void> _loadChannelDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/chat/channels/${widget.channelId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'uid': user.uid,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _channelDetails = json.decode(response.body);
        });
      }

      // Check if user is admin
      final bucketResponse = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/chat/buckets/${widget.bucketId}/members/'),
        headers: {
          'Authorization': 'Bearer $token',
          'uid': user.uid,
        },
      );

      if (bucketResponse.statusCode == 200) {
        final members = json.decode(bucketResponse.body);
        setState(() {
          _isAdmin = members.any((member) => member['user']['id'] == user.uid && member['role'] == 'admin');
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading channel details: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadMembers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/chat/channels/${widget.channelId}/members/'),
        headers: {
          'Authorization': 'Bearer $token',
          'uid': user.uid,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _members = json.decode(response.body);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading members: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();

      final response = await http.delete(
        Uri.parse('${dotenv.env['base_url']}/api/chat/channels/${widget.channelId}/members/$userId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'uid': user.uid,
        },
      );

      if (response.statusCode == 204) {
        _loadMembers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing member: ${e.toString()}')),
      );
    }
  }

  Future<void> _addMember(String email) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${dotenv.env['base_url']}/api/chat/channels/${widget.channelId}/members/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'uid': user.uid,
        },
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        _loadMembers();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding member: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddMemberDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: const Text('Add Member', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter email',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _addMember(emailController.text),
            child: _isLoading ? const CircularProgressIndicator() : const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_channelDetails == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: const Text('Channel Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Channel Details Section
          Card(
            color: AppColors.backgroundColor.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _channelDetails!['name'] ?? 'Channel Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _channelDetails!['channel_type'] ?? 'Channel Type',
                    style: TextStyle(color: AppColors.lightTextColor),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Members Section
          Card(
            color: AppColors.backgroundColor.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isAdmin)
                        IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.white),
                          onPressed: _showAddMemberDialog,
                        ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member['profile_picture'] != null ? NetworkImage(member['profile_picture']) : null,
                        child: member['profile_picture'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(
                        member['name'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        member['role'] ?? 'Member',
                        style: TextStyle(color: AppColors.lightTextColor),
                      ),
                      trailing: _isAdmin && member['user']['id'] != FirebaseAuth.instance.currentUser?.uid
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeMember(member['user']['id']),
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
