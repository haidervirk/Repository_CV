class User {
  final String name;
  final String email;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String profilePicture;
  final String phoneNumber;
  final String status;

  User({
    required this.name,
    required this.email,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
    required this.profilePicture,
    required this.phoneNumber,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profilePicture: json['profile_picture'],
      phoneNumber: json['phone_number'] ?? '',
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_picture': profilePicture,
      'phone_number': phoneNumber,
      'status': status,
    };
  }

  User copyWith({
    String? name,
    String? email,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePicture,
    String? phoneNumber,
    String? status,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePicture: profilePicture ?? this.profilePicture,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
    );
  }

  // default user
  static User default_() {
    return User(
      name: '',
      email: '',
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      profilePicture: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSpwxCN33LtdMLbWdhafc4HxabqpaU0qVbDxQ&s',
      phoneNumber: '',
      status: 'Active',
    );
  }
}

class UserPushToken {
  final User user;
  final String pushToken;
  final DateTime createdAt;

  UserPushToken({
    required this.user,
    required this.pushToken,
    required this.createdAt,
  });

  factory UserPushToken.fromJson(Map<String, dynamic> json) {
    return UserPushToken(
      user: User.fromJson(json['user']),
      pushToken: json['push_token'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'push_token': pushToken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
