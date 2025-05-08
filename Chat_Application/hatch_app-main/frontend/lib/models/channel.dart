
class ChannelModel {
  final int channelId;
  final String channelName;
  final String? latestMessage;
  final String? latestSender;
  final String? latestSenderId;
  final String? timestamp;

  ChannelModel({
    required this.channelId,
    required this.channelName,
    this.latestMessage,
    this.latestSender,
    this.latestSenderId,
    this.timestamp,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      channelId: json['channel_id'],
      channelName: json['channel_name'],
      latestMessage: json['latest_message'],
      latestSender: json['latest_sender'],
      latestSenderId: json['latest_sender_id']?.toString(),
      timestamp: json['timestamp'],
    );
  }
}
