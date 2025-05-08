class ChatItem {
  final int channelId;
  final String channelName;
  final String profilePicture;
  final String latestMessage;
  final String latestSenderName;
  final String latestSenderId;
  final DateTime timestamp;

  ChatItem({
    required this.channelId,
    required this.channelName,
    required this.profilePicture,
    required this.latestMessage,
    required this.latestSenderName,
    required this.latestSenderId,
    required this.timestamp,
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) {
    return ChatItem(
      channelId: json['channel_id'],
      channelName: json['channel_name'],
      profilePicture: json['profile_picture'],
      latestMessage: json['latest_message'],
      latestSenderName: json['latest_sender_name'],
      latestSenderId: json['latest_sender_id'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'channel_name': channelName,
      'profile_picture': profilePicture,
      'latest_message': latestMessage,
      'latest_sender_name': latestSenderName,
      'latest_sender_id': latestSenderId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatItem.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatItem(
      channelId: int.parse(id), // Use the document ID as channel_id
      channelName: data['channel_name'],
      profilePicture: data['profile_picture'],
      latestMessage: data['latest_message'],
      latestSenderName: data['latest_sender_name'],
      latestSenderId: data['latest_sender_id'],
      timestamp: DateTime.parse(data['timestamp']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'channel_name': channelName,
      'profile_picture': profilePicture,
      'latest_message': latestMessage,
      'latest_sender_name': latestSenderName,
      'latest_sender_id': latestSenderId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 2) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${difference.inDays ~/ 7}w';
    }
  }
}
