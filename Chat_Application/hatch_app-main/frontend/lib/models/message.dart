class ChatMessage {
  final String id;
  final String senderName;
  final String senderEmail;
  final String senderId;
  final String text;
  final String? messageFile;
  final String? reaction;
  final String time;
  final String channelId;
  final String? joinChannel;
  final bool isUser;
  final String status;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.senderId,
    required this.text,
    this.messageFile,
    required this.reaction,
    required this.time,
    required this.channelId,
    this.joinChannel,
    required this.isUser,
    required this.status,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      senderName: json['sender_name'],
      senderEmail: json['sender_email'],
      senderId: json['sender_id'],
      text: json['text'],
      messageFile: json['message_file'],
      reaction: json['reaction'],
      time: json['time'],
      channelId: json['channel_id'],
      joinChannel: json['join_channel'],
      isUser: false,
      status: json['status'] ?? 'sent',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id && other.senderName == senderName && other.senderEmail == senderEmail && other.senderId == senderId && other.text == text && other.messageFile == messageFile && other.reaction == reaction && other.time == time && other.channelId == channelId && other.isUser == isUser && other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      senderName,
      senderEmail,
      senderId,
      text,
      messageFile,
      reaction,
      time,
      channelId,
      joinChannel,
      isUser,
      status,
    );
  }
}
