class User {
  final String id;
  final String username;
  final String profilePicture;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.profilePicture,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'] ?? '',
      token: json['token'],
    );
  }
}

class UserWithLastMessage {
  final String id;
  final String username;
  final String profilePicture;
  final String? lastMessageContent;
  final DateTime? lastMessageTimestamp;

  UserWithLastMessage({
    required this.id,
    required this.username,
    required this.profilePicture,
    this.lastMessageContent,
    this.lastMessageTimestamp,
  });

  factory UserWithLastMessage.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['lastMessage'];
    return UserWithLastMessage(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'],
      lastMessageContent: lastMessage?['content'],
      lastMessageTimestamp: lastMessage?['timestamp'] != null
          ? DateTime.parse(lastMessage['timestamp'])
          : null,
    );
  }
}
