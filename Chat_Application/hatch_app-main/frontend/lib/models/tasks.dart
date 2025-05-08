class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final String assignedByName;
  final String assignedToName;
  final DateTime dueDate;
  final DateTime createdAt;
  final String assignedToId;
  final String assignedById;
  final int communityId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedByName,
    required this.assignedToName,
    required this.dueDate,
    required this.createdAt,
    required this.assignedToId,
    required this.assignedById,
    required this.communityId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    print(json);
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      assignedByName: json['assigned_by_name'],
      assignedToName: json['assigned_to_name'],
      dueDate: DateTime.parse(json['due_date']),
      createdAt: DateTime.parse(json['created_at']),
      assignedToId: json['assigned_to'],
      assignedById: json['assigned_by'],
      communityId: json['community'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'assigned_by_name': assignedByName,
      'assigned_to_name': assignedToName,
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'assigned_to': assignedToId,
      'assigned_by': assignedById,
      'community': communityId,
    };
  }
}
