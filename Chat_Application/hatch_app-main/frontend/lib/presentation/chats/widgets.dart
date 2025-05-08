import 'package:flutter/material.dart';
import 'package:frontend/models/chat_item.dart';
import 'package:frontend/presentation/chats/chat.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';

class ChatListTile extends StatelessWidget {
  final ChatItem chatItem;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chatItem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = currentUser?.uid == chatItem.latestSenderId;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(chatItem.profilePicture),
      ),
      title: Text(
        chatItem.channelName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isCurrentUser ? 'You: ${chatItem.latestMessage}' : chatItem.latestMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        chatItem.timeAgo,
        style: TextStyle(color: Colors.grey[400]),
      ),
      onTap: onTap,
    );
  }
}

// Search bar widget
class ChatSearchBar extends StatelessWidget {
  const ChatSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(color: AppColors.textColor, fontSize: 16),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search',
            alignLabelWithHint: true,
            hintStyle: TextStyle(color: AppColors.lightTextColor),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            suffixIcon: Icon(Icons.search, color: AppColors.lighterTextColor),
          ),
        ),
      ),
    );
  }
}

// Chat list widget
class ChatList extends StatelessWidget {
  final List<ChatItem> chatItems;

  const ChatList({super.key, required this.chatItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chatItems.length,
      itemBuilder: (context, index) {
        return ChatListTile(
          chatItem: chatItems[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatItem: chatItems[index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.4,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onJoinChannel;

  const ChatBubble({
    super.key,
    required this.message,
    this.onJoinChannel,
  });

  @override
  Widget build(BuildContext context) {
    if (message.status == 'failed') {
      return ErrorScreen(
        emoji: '❌',
        title: 'Message Failed to Send',
        description: 'There was an error sending your message. Please check your connection and try again.',
        onRetry: () {
          // Implement retry logic here
        },
      );
    }

    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? const Color(0xFF1f2c34) : const Color(0xFF6355d9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                message.senderName,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
          Align(
            alignment: alignment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (message.messageFile != null && message.messageFile!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        // onTap: () => _launchURL(message.messageFile!),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attachment, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Attachment',
                                style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (message.joinChannel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: onJoinChannel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: bubbleColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Join Channel'),
                      ),
                    ),
                  const SizedBox(height: 4),
                  message.reaction != null
                      ? Text(
                          "${DateFormat('h:mm a').format(DateTime.parse(message.time).toLocal())} ・ ${message.reaction!}",
                          style: TextStyle(color: Colors.grey[300], fontSize: 10),
                        )
                      : Text(
                          DateFormat('h:mm a').format(DateTime.parse(message.time).toLocal()),
                          style: TextStyle(color: Colors.grey[300], fontSize: 10),
                        ),
                ],
              ),
            ),
          ),
          if (isUser && message.status == 'sending')
            Text(
              'Sending...',
              style: TextStyle(color: Colors.grey[300], fontSize: 10),
            ),
        ],
      ),
    );
  }
}
