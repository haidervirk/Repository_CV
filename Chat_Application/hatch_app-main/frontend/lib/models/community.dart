class Community {
  final int id;
  final String name;
  final String members;
  final String avatarUrl;
  final List<SubGroup> subGroups;

  Community({
    required this.id,
    required this.name,
    required this.members,
    required this.avatarUrl,
    required this.subGroups,
  });
}

class SubGroup {
  final int id;
  final String tag;
  final String message;
  final String time;

  SubGroup({
    required this.id,
    required this.tag,
    required this.message,
    required this.time,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(DateTime.parse(time));

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
