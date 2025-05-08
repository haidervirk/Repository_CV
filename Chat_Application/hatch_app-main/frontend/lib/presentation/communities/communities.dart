import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/presentation/communities/create_communities.dart';
import 'package:frontend/presentation/communities/widgets.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/community.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  List<Community> communities = [];
  List<Community> allCommunities = []; // for search reference
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCommunities();
    _searchController.addListener(_filterCommunities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    try {
      final fetched = await _fetchCommunities();
      setState(() {
        allCommunities = fetched;
        communities = fetched;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<List<Community>> _fetchCommunities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final token = await user.getIdToken();
    final response = await http.get(
      Uri.parse(
          '${dotenv.env['base_url']}/api/chat/direct-messages/communities/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'uid': user.uid,
      },
    );

    if (response.statusCode == 200) {
      return _parseCommunities(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('User not authenticated');
    } else {
      throw Exception('Failed to load communities');
    }
  }

  List<Community> _parseCommunities(String responseBody) {
    final List<dynamic> bucketList = json.decode(responseBody);
    return bucketList.map((bucket) {
      final List<dynamic> channels = bucket['channels_list'];
      return Community(
        id: bucket['Bucket ID'],
        name: bucket['Bucket Name'],
        members: '${bucket['Member Count']} members',
        avatarUrl:
            bucket['Bucket Picture'] ?? 'https://via.placeholder.com/150',
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
  }

  void _filterCommunities() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => communities = List.from(allCommunities));
    } else {
      setState(() {
        communities = allCommunities.where((community) {
          return community.name.toLowerCase().contains(query) ||
              community.members.toLowerCase().contains(query) ||
              community.subGroups.any((sub) =>
                  sub.tag.toLowerCase().contains(query) ||
                  sub.message.toLowerCase().contains(query));
        }).toList();
      });
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bottomSheetBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: AppColors.textColor, fontSize: 16),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search communities, messages, or channels',
            hintStyle: TextStyle(color: AppColors.lightTextColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: Icon(Icons.search, color: AppColors.lighterTextColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    if (communities.isEmpty) {
      return const Center(child: Text('No matching communities found.'));
    }
    return ListView.builder(
      itemCount: communities.length,
      itemBuilder: (context, index) {
        return CommunityCard(
          community: communities[index],
          fetchCommunities: _loadCommunities,
        );
      },
    );
  }

  void _navigateToCreateCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateCommunityScreen()),
    ).then((_) => _loadCommunities());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF293247),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Communities',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCommunities,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateCommunity,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
