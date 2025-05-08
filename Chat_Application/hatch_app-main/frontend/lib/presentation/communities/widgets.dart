import 'package:flutter/material.dart';
import 'package:frontend/models/chat_item.dart';
import 'package:frontend/presentation/chats/chat.dart';
import 'package:frontend/models/community.dart';
import 'package:frontend/presentation/communities/channel_settings.dart';
import 'package:frontend/presentation/communities/community_detail.dart';
import 'package:frontend/presentation/communities/create_communities.dart';

class CommunityCard extends StatefulWidget {
  final Community community;
  final Function fetchCommunities;

  const CommunityCard({super.key, required this.community, required this.fetchCommunities});

  @override
  State<CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard> {
  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
      child: const Icon(
        Icons.groups,
        color: Colors.black,
        size: 20,
      ),
    );
  }

  Widget _buildCommunityInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.community.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          widget.community.members,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _handleAddTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCommunityScreen(
          bucketId: widget.community.id.toString(),
          bucketName: widget.community.name,
        ),
      ),
    ).then((value) {
      widget.fetchCommunities();
    });
  }

  void _handleSettingsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelSettingsScreen(
          bucketId: widget.community.id.toString(),
          channelId: widget.community.subGroups[0].id.toString(),
        ),
      ),
    );
  }

  void _handleLongPress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailScreen(
          communityName: widget.community.name,
          bucketId: widget.community.id.toString(),
          channelId: widget.community.subGroups[0].id.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _handleLongPress,
      child: Container(
        color: const Color(0xFF293247),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            collapsedBackgroundColor: const Color(0xFF293247),
            backgroundColor: const Color(0xFF293247),
            title: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 8),
                Expanded(child: _buildCommunityInfo()),
              ],
            ),
            trailing: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  onTap: _handleAddTap,
                  icon: Icons.add,
                ),
              ],
            ),
            onExpansionChanged: (bool expanded) {},
            children: widget.community.subGroups.map((sub) => SubGroupTile(subGroup: sub)).toList(),
          ),
        ),
      ),
    );
  }
}

class SubGroupTile extends StatelessWidget {
  final SubGroup subGroup;

  const SubGroupTile({super.key, required this.subGroup});

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatItem: _createChatItem(),
        ),
      ),
    );
  }

  ChatItem _createChatItem() {
    return ChatItem(
      channelId: subGroup.id,
      channelName: subGroup.tag,
      profilePicture: subGroup.id.toString(),
      latestMessage: subGroup.message,
      latestSenderName: subGroup.time,
      latestSenderId: subGroup.time,
      timestamp: DateTime.now(),
    );
  }

  Widget _buildMessagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subGroup.tag,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subGroup.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToChat(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(32, 0, 4, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1f2c34),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: _buildMessagePreview()),
            const SizedBox(width: 8),
            Text(
              subGroup.timeAgo,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
