class User {
  final String id;
  final String username;
  final String profilePicture;
  final String? token;
  final String? email;
  final bool? isAdded;

  User({
    required this.id,
    required this.username,
    required this.profilePicture,
    this.token,
    this.email,
    this.isAdded,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'] ?? '',
      token: json['token'],
      email: json['email'],
      isAdded: json['isAdded'] ?? json['addedYou'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? profilePicture,
    String? token,
    String? email,
    bool? isAdded,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      token: token ?? this.token,
      email: email ?? this.email,
      isAdded: isAdded ?? this.isAdded,
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
  final bool? isSender;

  UserWithLastMessage(
      {required this.id,
      required this.username,
      required this.profilePicture,
      this.email,
      this.lastMessageContent,
      this.lastMessageTimestamp,
      this.isSender});

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
      isSender: lastMessage?['isSender'],
    );
  }
}
