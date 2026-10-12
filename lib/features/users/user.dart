/// Friend-request state between the authenticated user and another user.
/// Messaging, voice, and video calls all require [accepted] — see the
/// backend's AreFriends gate in signaling/users.go.
enum ContactStatus {
  none,
  pendingSent,
  pendingReceived,
  accepted;

  static ContactStatus fromJson(String? value) {
    switch (value) {
      case 'pending_sent':
        return ContactStatus.pendingSent;
      case 'pending_received':
        return ContactStatus.pendingReceived;
      case 'accepted':
        return ContactStatus.accepted;
      default:
        return ContactStatus.none;
    }
  }
}

class User {
  final String id;
  final String username;
  final String profilePicture;
  final String? token;
  final String? email;
  final ContactStatus contactStatus;
  final String? fcmToken;

  User({
    required this.id,
    required this.username,
    required this.profilePicture,
    this.token,
    this.email,
    this.contactStatus = ContactStatus.none,
    this.fcmToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'] ?? '',
      token: json['token'],
      email: json['email'],
      contactStatus: ContactStatus.fromJson(json['contactStatus']),
      fcmToken: json['fcm_token'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? profilePicture,
    String? token,
    String? email,
    ContactStatus? contactStatus,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      token: token ?? this.token,
      email: email ?? this.email,
      contactStatus: contactStatus ?? this.contactStatus,
      fcmToken: fcmToken ?? this.fcmToken,
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
  final int unreadCount;

  UserWithLastMessage({
    required this.id,
    required this.username,
    required this.profilePicture,
    this.email,
    this.lastMessageContent,
    this.lastMessageTimestamp,
    this.isSender,
    this.unreadCount = 0,
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
      isSender: lastMessage?['isSender'],
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  UserWithLastMessage copyWith({
    String? lastMessageContent,
    DateTime? lastMessageTimestamp,
    bool? isSender,
    int? unreadCount,
  }) {
    return UserWithLastMessage(
      id: id,
      username: username,
      profilePicture: profilePicture,
      email: email,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      isSender: isSender ?? this.isSender,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
