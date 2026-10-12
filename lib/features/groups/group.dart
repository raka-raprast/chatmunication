class Group {
  final String id;
  final String name;
  final String picture;
  final String createdBy;

  Group({
    required this.id,
    required this.name,
    required this.picture,
    required this.createdBy,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      picture: json['picture'] ?? '',
      createdBy: json['created_by'],
    );
  }
}

class GroupMember {
  final String id;
  final String username;
  final String profilePicture;
  final bool isCreator;

  /// Whether the requesting user has this member as an accepted contact.
  /// Defaults true so old cached/incomplete payloads don't flash a false
  /// "stranger" badge for people who are actually contacts.
  final bool isContact;

  GroupMember({
    required this.id,
    required this.username,
    required this.profilePicture,
    required this.isCreator,
    this.isContact = true,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'] ?? '',
      isCreator: json['isCreator'] ?? false,
      isContact: json['isContact'] ?? true,
    );
  }
}

class GroupWithLastMessage {
  final String id;
  final String name;
  final String picture;
  final String createdBy;
  final int memberCount;
  final String? lastMessageContent;
  final String? lastMessageSenderName;
  final DateTime? lastMessageTimestamp;
  final bool? isSender;
  final bool lastMessageIsSystem;
  final int unreadCount;

  GroupWithLastMessage({
    required this.id,
    required this.name,
    required this.picture,
    required this.createdBy,
    this.memberCount = 0,
    this.lastMessageContent,
    this.lastMessageSenderName,
    this.lastMessageTimestamp,
    this.isSender,
    this.lastMessageIsSystem = false,
    this.unreadCount = 0,
  });

  factory GroupWithLastMessage.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['lastMessage'];
    return GroupWithLastMessage(
      id: json['id'],
      name: json['name'],
      picture: json['picture'] ?? '',
      createdBy: json['created_by'],
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      lastMessageContent: lastMessage?['content'],
      lastMessageSenderName: lastMessage?['senderName'],
      lastMessageTimestamp: lastMessage?['timestamp'] != null
          ? DateTime.parse(lastMessage['timestamp'])
          : null,
      isSender: lastMessage?['isSender'],
      lastMessageIsSystem: lastMessage?['isSystem'] ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  GroupWithLastMessage copyWith({
    String? lastMessageContent,
    String? lastMessageSenderName,
    DateTime? lastMessageTimestamp,
    bool? isSender,
    bool? lastMessageIsSystem,
    int? unreadCount,
  }) {
    return GroupWithLastMessage(
      id: id,
      name: name,
      picture: picture,
      createdBy: createdBy,
      memberCount: memberCount,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      isSender: isSender ?? this.isSender,
      lastMessageIsSystem: lastMessageIsSystem ?? this.lastMessageIsSystem,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class GroupChatMessage {
  final String fromUserId;
  final String content;
  final DateTime timestamp;
  final bool isSystem;

  GroupChatMessage({
    required this.fromUserId,
    required this.content,
    required this.timestamp,
    this.isSystem = false,
  });

  factory GroupChatMessage.fromJson(Map<String, dynamic> json) {
    return GroupChatMessage(
      fromUserId: json['FromUserID'],
      content: json['Content'],
      timestamp: DateTime.parse(json['Timestamp']),
      isSystem: json['IsSystem'] ?? false,
    );
  }
}

class GroupInvite {
  final String inviteId;
  final String groupId;
  final String groupName;
  final String picture;
  final String invitedBy;
  final DateTime createdAt;

  GroupInvite({
    required this.inviteId,
    required this.groupId,
    required this.groupName,
    required this.picture,
    required this.invitedBy,
    required this.createdAt,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      inviteId: json['inviteId'],
      groupId: json['groupId'],
      groupName: json['groupName'],
      picture: json['picture'] ?? '',
      invitedBy: json['invitedBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
