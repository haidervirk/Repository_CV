import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/chat_item.dart';
import 'package:frontend/presentation/users.dart';
import 'package:frontend/presentation/chats/chatbot.dart' as chatbot_ui;
import 'package:frontend/theme/app_colors.dart';
import 'create_chat.dart';
import 'services.dart';
import 'widgets.dart';

class HatchHomeScreen extends ConsumerStatefulWidget {
  const HatchHomeScreen({super.key});

  @override
  ConsumerState<HatchHomeScreen> createState() => _HatchHomeScreenState();
}

class _HatchHomeScreenState extends ConsumerState<HatchHomeScreen> {
  Timer? _refreshTimer;
  List<ChatItem> _chatItems = [];
  List<ChatItem> _filteredItems = [];
  bool _isLoading = true;
  Exception? _error;
  bool _isRefreshing = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(userProvider.notifier).fetchUserData();
    _initializeData();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeData() {
    _fetchChatItems();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _silentRefresh());
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _chatItems.where((chat) {
        return chat.channelName.toLowerCase().contains(query) || chat.latestSenderName.toLowerCase().contains(query) || chat.latestMessage.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _silentRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final items = await ChatService.fetchChatItems();
      if (mounted) {
        setState(() {
          _chatItems = items;
          _filteredItems = items; // Keep filtered list in sync
          _error = null;
        });
      }
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _fetchChatItems() async {
    try {
      final items = await ChatService.fetchChatItems();
      if (mounted) {
        setState(() {
          _chatItems = items;
          _filteredItems = items;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e as Exception;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildChatList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      if (_error is AuthException) {
        return ErrorScreen(
          emoji: '🔒',
          title: 'Authentication Required',
          description: _error.toString(),
          onRetry: _fetchChatItems,
        );
      } else if (_error is NetworkException) {
        return ErrorScreen(
          emoji: '🌐',
          title: 'Connection Error',
          description: _error.toString(),
          onRetry: _fetchChatItems,
        );
      } else {
        return ErrorScreen(
          emoji: '😕',
          title: 'Oops!',
          description: 'Something went wrong. Please try again.',
          onRetry: _fetchChatItems,
        );
      }
    } else if (_filteredItems.isEmpty) {
      return const Center(child: Text('No results found.', style: TextStyle(color: Colors.white)));
    } else {
      return ChatList(chatItems: _filteredItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF293247),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Hatch',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.smart_toy_rounded, color: AppColors.textColor),
            tooltip: 'Ask Sensei',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const chatbot_ui.ChatScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search chats, messages, people...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: AppColors.bottomSheetBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            context: context,
            builder: (context) => const CreateChatScreen(),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
