import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/chat_item.dart';
import 'package:frontend/presentation/chats/chat.dart';
import 'package:frontend/presentation/tasks/task_details_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/presentation/communities/channel_settings.dart';
import 'package:frontend/models/tasks.dart';
import 'package:frontend/models/channel.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityName;
  final String bucketId;
  final String channelId;

  const CommunityDetailScreen({
    super.key,
    required this.communityName,
    required this.bucketId,
    required this.channelId,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  List<Task> taskList = [];
  List<ChannelModel> channelList = [];
  String selectedPeriod = 'Today';
  String selectedTaskFilter = 'All';
  String selectedChannelFilter = 'All';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/task/get_community_settings/${widget.bucketId}'),
        headers: {
          'Content-Type': 'application/json',
          'uid': FirebaseAuth.instance.currentUser!.uid,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        setState(() {
          channelList = (data['channels'] as List).map((channel) => ChannelModel.fromJson(channel)).where((channel) => selectedChannelFilter == 'All' || channel.channelName.contains(selectedChannelFilter)).toList();

          taskList = (data['tasks'] as List)
              .map((task) => Task(
                    id: task['id'],
                    title: task['title'],
                    description: task['description'],
                    status: task['status'],
                    dueDate: DateTime.parse(task['due_date']),
                    assignedByName: task['assigned_by'] ?? '',
                    assignedToName: task['assigned_to'] ?? '',
                    createdAt: task['created_at'] != null ? DateTime.parse(task['created_at']) : DateTime.now(),
                    assignedToId: task['assigned_to'] ?? '',
                    assignedById: task['assigned_by'] ?? '',
                    communityId: task['community'] ?? 0,
                  ))
              .where((task) => selectedTaskFilter == 'All' || task.status.toLowerCase() == selectedTaskFilter.toLowerCase())
              .toList();
        });
      } else {
        throw Exception('Failed to load community data');
      }
    } catch (e) {
      print('Error loading data: $e');
      // Handle error appropriately
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onTaskFilterChange(String filter) {
    setState(() => selectedTaskFilter = filter);
    _loadData();
  }

  void _onChannelFilterChange(String filter) {
    setState(() => selectedChannelFilter = filter);
    _loadData();
  }

  Widget _buildRoundedChip(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.primaryColor : AppColors.lighterTextColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.lighterTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChannelItem(ChannelModel channel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatItem: ChatItem(
                channelId: channel.channelId,
                channelName: channel.channelName,
                profilePicture: "",
                latestMessage: channel.latestMessage ?? '',
                latestSenderName: channel.latestSender ?? '',
                latestSenderId: channel.latestSenderId ?? '',
                timestamp: channel.timestamp != null ? DateTime.parse(channel.timestamp!) : DateTime.now(),
              ),
            ),
          ),
        );
      },
      child: Row(
        children: [
          Icon(Icons.tag, color: AppColors.textColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${channel.channelName}', style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold)),
                if (channel.latestMessage != null) ...[
                  const SizedBox(height: 4),
                  Text('${channel.latestSender}: ${channel.latestMessage}', style: TextStyle(color: AppColors.lighterTextColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String value) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.bottomSheetBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor, width: 1.2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(color: AppColors.textColor, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: AppColors.lighterTextColor, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTab(String label, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primaryColor : AppColors.lighterTextColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.lighterTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bottomSheetBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: TextStyle(color: AppColors.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(task.description, style: TextStyle(color: AppColors.lighterTextColor, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Assigned by: ${task.assignedByName}', style: TextStyle(color: AppColors.lighterTextColor, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Due: ${task.dueDate.toString().split(' ')[0]}', style: TextStyle(color: AppColors.lighterTextColor, fontSize: 13)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoadingIndicator() : _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.communityName),
      backgroundColor: AppColors.bottomSheetBgColor,
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildChannelSection(),
        const Divider(thickness: 0.5, color: Colors.grey),
        const SizedBox(height: 16),
        _buildTasksHeader(),
        const SizedBox(height: 16),
        _buildTasksSummary(),
        const SizedBox(height: 16),
        _buildTasksFilter(),
        const SizedBox(height: 16),
        _buildTasksList(),
      ],
    );
  }

  Widget _buildChannelSection() {
    return Column(
      children: [
        _buildChannelFilter(),
        const SizedBox(height: 24),
        _buildChannelList(),
      ],
    );
  }

  Widget _buildChannelFilter() {
    return Row(
      children: ['All'].map((label) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _onChannelFilterChange(label),
            child: _buildRoundedChip(
              label,
              selected: selectedChannelFilter == label,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChannelList() {
    return Column(
      children: [
        for (var channel in channelList) ...[
          _buildChannelItem(channel),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildTasksHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Tasks",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        _buildPeriodDropdown(),
      ],
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: AppColors.bottomSheetBgColor,
          value: selectedPeriod,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textColor, size: 16),
          style: TextStyle(color: AppColors.textColor),
          onChanged: (String? newValue) {
            setState(() => selectedPeriod = newValue!);
          },
          items: ['Today', 'Last Week', 'Last Month']
              .map((value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTasksSummary() {
    return Row(
      children: [
        _buildSummaryBox("Assigned tasks", taskList.length.toString()),
        const SizedBox(width: 12),
        _buildSummaryBox(
          "Completed tasks",
          taskList.where((task) => task.status.toLowerCase() == "completed").length.toString(),
        ),
      ],
    );
  }

  Widget _buildTasksFilter() {
    return Container(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4, right: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'open', 'in progress', 'completed'].map((label) {
            return GestureDetector(
              onTap: () => _onTaskFilterChange(label),
              child: _buildTaskTab(
                label,
                selected: selectedTaskFilter.toLowerCase() == label.toLowerCase(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Column(
      children: [
        for (var task in taskList) ...[
          _buildTaskCard(task),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChannelSettingsScreen(
              bucketId: widget.bucketId,
              channelId: widget.channelId,
            ),
          ),
        );
      },
      backgroundColor: AppColors.primaryColor,
      child: const Icon(Icons.add),
    );
  }
}
