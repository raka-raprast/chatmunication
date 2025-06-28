class User {
  final String id;
  final String username;
  final String profilePicture;
  final String? token;
  final String? email;

  User({
    required this.id,
    required this.username,
    required this.profilePicture,
    this.token,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'] ?? '',
      token: json['token'],
      email: json['email'],
    );
  }
}

class UserWithLastMessage {
  final String id;
  final String username;
  final String profilePicture;
  final String? lastMessageContent;
  final String? email;
  final DateTime? lastMessageTimestamp;

  UserWithLastMessage({
    required this.id,
    required this.username,
    required this.profilePicture,
    this.email,
    this.lastMessageContent,
    this.lastMessageTimestamp,
  });

  factory UserWithLastMessage.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['lastMessage'];
    return UserWithLastMessage(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'],
      email: json['email'],
      lastMessageContent: lastMessage?['content'],
      lastMessageTimestamp: lastMessage?['timestamp'] != null
          ? DateTime.parse(lastMessage['timestamp'])
          : null,
    );
  }
}
