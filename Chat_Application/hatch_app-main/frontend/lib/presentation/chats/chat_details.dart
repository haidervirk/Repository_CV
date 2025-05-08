import 'package:flutter/material.dart';
import 'package:frontend/models/chat_item.dart';
import 'package:frontend/theme/app_colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatItem chatItem;
  final String searchTerm;

  const ChatDetailScreen({
    super.key,
    required this.chatItem,
    required this.searchTerm,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  late List<String> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _loadDummyMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSearch());
  }

  List<String> _loadDummyMessages() {
    return List.generate(
      100,
      (index) => index == 42
          ? 'Message containing ${widget.searchTerm}'
          : 'Chat message $index',
    );
  }

  void _scrollToSearch() {
    final index = _messages.indexWhere((msg) =>
        widget.searchTerm.isNotEmpty &&
        msg.toLowerCase().contains(widget.searchTerm.toLowerCase()));
    if (index != -1) {
      _scrollController.animateTo(
        index * 72.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.bottomSheetBgColor,
        title: Text(widget.chatItem.channelName),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final isMatch = widget.searchTerm.isNotEmpty &&
              msg.toLowerCase().contains(widget.searchTerm.toLowerCase());
          return Container(
            padding: const EdgeInsets.all(16),
            color: isMatch ? Colors.yellow.withOpacity(0.3) : null,
            child: Text(
              msg,
              style: TextStyle(
                color: isMatch ? Colors.black : Colors.white,
                fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
