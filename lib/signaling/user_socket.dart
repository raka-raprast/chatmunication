import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';

/// A new member accepted an invite — see signaling.BroadcastGroupMemberJoined
/// server-side. Carries enough to update an already-open group screen's
/// member list, header count, and message timeline without a refetch.
typedef GroupMemberJoinedListener = void Function(
  String groupId,
  String userId,
  String username,
  String profilePicture,
  bool isContact,
  int memberCount,
  String content,
  String timestamp,
);

class UserSocketService {
  static final UserSocketService instance = UserSocketService._internal();

  // Private constructor
  UserSocketService._internal();

  // Call `init(...)` once before using
  late String token;
  late String userId;
  late String serverUrl;

  /// The conversation currently open on screen (if any). Lets other
  /// listeners — e.g. the chat list — know a message was already seen in
  /// real time and shouldn't bump the unread badge.
  String? activeChatUserId;

  /// The group conversation currently open on screen (if any) — same
  /// purpose as [activeChatUserId] but for group chats.
  String? activeGroupId;

  late void Function(
    String fromUserId,
    String roomId,
    String fromName,
    String profilePicture,
    String callType,
  )
  onIncomingCall;

  late void Function(String roomId) onCallAccepted;
  late void Function() onCallRejected;
  void Function()? onCallCancelled;
  void Function(String userId, bool isOnline)? onOnlineStatusChanged;
  void Function(List<String> onlineUserIds)? onInitialOnlineUsers;
  void Function(
    String inviteId,
    String groupId,
    String groupName,
    String picture,
    String invitedBy,
  )?
  onGroupInvite;

  // Unlike the single-callback fields above, incoming chat messages and
  // typing status fan out to more than one screen at once (e.g. the chat
  // list showing a live preview/typing state while a MessageScreen for
  // that same conversation is also open) — plain nullable fields would
  // let whichever screen registers last silently clobber the other's
  // handler, so these use listener lists instead.
  final List<void Function(String fromUserId, String content, String timestamp)>
  _messageListeners = [];
  final List<void Function(String fromUserId, bool isTyping)> _typingListeners =
      [];

  void addMessageListener(
    void Function(String fromUserId, String content, String timestamp) listener,
  ) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(
    void Function(String fromUserId, String content, String timestamp) listener,
  ) {
    _messageListeners.remove(listener);
  }

  void addTypingListener(
    void Function(String fromUserId, bool isTyping) listener,
  ) {
    _typingListeners.add(listener);
  }

  void removeTypingListener(
    void Function(String fromUserId, bool isTyping) listener,
  ) {
    _typingListeners.remove(listener);
  }

  final List<
    void Function(
      String groupId,
      String fromUserId,
      String content,
      String timestamp,
    )
  >
  _groupMessageListeners = [];
  final List<void Function(String groupId, String fromUserId, bool isTyping)>
  _groupTypingListeners = [];
  final List<GroupMemberJoinedListener> _groupMemberJoinedListeners = [];

  void addGroupMessageListener(
    void Function(
      String groupId,
      String fromUserId,
      String content,
      String timestamp,
    )
    listener,
  ) {
    _groupMessageListeners.add(listener);
  }

  void removeGroupMessageListener(
    void Function(
      String groupId,
      String fromUserId,
      String content,
      String timestamp,
    )
    listener,
  ) {
    _groupMessageListeners.remove(listener);
  }

  void addGroupTypingListener(
    void Function(String groupId, String fromUserId, bool isTyping) listener,
  ) {
    _groupTypingListeners.add(listener);
  }

  void removeGroupTypingListener(
    void Function(String groupId, String fromUserId, bool isTyping) listener,
  ) {
    _groupTypingListeners.remove(listener);
  }

  void addGroupMemberJoinedListener(GroupMemberJoinedListener listener) {
    _groupMemberJoinedListeners.add(listener);
  }

  void removeGroupMemberJoinedListener(GroupMemberJoinedListener listener) {
    _groupMemberJoinedListeners.remove(listener);
  }

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;

  void init({
    required String token,
    required String userId,
    required String serverUrl,
    required void Function(
      String fromUserId,
      String roomId,
      String fromName,
      String profilePicture,
      String callType,
    )
    onIncomingCall,
    required void Function(String roomId) onCallAccepted,
    required void Function() onCallRejected,
    void Function()? onCallCancelled,
    void Function(String userId, bool isOnline)? onOnlineStatusChanged,
    void Function(List<String> onlineUserIds)? onInitialOnlineUsers,
    void Function(
      String inviteId,
      String groupId,
      String groupName,
      String picture,
      String invitedBy,
    )?
    onGroupInvite,
  }) {
    this.token = token;
    this.userId = userId;
    this.serverUrl = serverUrl;
    this.onIncomingCall = onIncomingCall;
    this.onCallAccepted = onCallAccepted;
    this.onCallRejected = onCallRejected;
    this.onCallCancelled = onCallCancelled;
    this.onOnlineStatusChanged = onOnlineStatusChanged;
    this.onInitialOnlineUsers = onInitialOnlineUsers;
    this.onGroupInvite = onGroupInvite;
  }

  /// Opens the persistent presence/signaling socket. Unlike the original
  /// fire-and-forget connect, this self-heals: a dropped connection (network
  /// blip, backend restart, app backgrounded long enough for the OS to kill
  /// the socket) schedules an automatic reconnect instead of leaving the
  /// app silently stuck with a dead channel until it's force-restarted.
  void connect() {
    _disposed = false;
    _reconnectTimer?.cancel();
    _subscription?.cancel();

    final uri = Uri.parse('$serverUrl/user-socket?userId=$userId');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;

    _subscription = channel.stream.listen(
      (event) {
        _reconnectAttempt = 0;
        final data = jsonDecode(event);
        final type = data['type'];

        switch (type) {
          case 'online_status':
            final userId = data['userId'];
            final isOnline = data['status'] == 'online';
            onOnlineStatusChanged?.call(userId, isOnline);
            break;

          case 'online_users':
            final ids = List<String>.from(data['onlineUsers'] ?? []);
            onInitialOnlineUsers?.call(ids);
            break;

          case 'incoming_call':
            onIncomingCall(
              data['from'],
              data['room'],
              data['username'],
              data['profile_picture'],
              data['call_type'],
            );
            break;

          case 'call_accepted':
            onCallAccepted(data['room']);
            break;

          case 'call_rejected':
            onCallRejected();
            break;

          case 'call_cancelled':
            onCallCancelled?.call();
            break;

          case 'chat_message':
            for (final listener in List.of(_messageListeners)) {
              listener(data['from'], data['content'], data['timestamp']);
            }
            break;

          case 'typing':
            final isTyping = data['isTyping'] == true;
            for (final listener in List.of(_typingListeners)) {
              listener(data['from'], isTyping);
            }
            break;

          case 'group_message':
            for (final listener in List.of(_groupMessageListeners)) {
              listener(
                data['groupId'],
                data['from'],
                data['content'],
                data['timestamp'],
              );
            }
            break;

          case 'group_typing':
            final isTyping = data['isTyping'] == true;
            for (final listener in List.of(_groupTypingListeners)) {
              listener(data['groupId'], data['from'], isTyping);
            }
            break;

          case 'group_invite':
            onGroupInvite?.call(
              data['inviteId'],
              data['groupId'],
              data['groupName'],
              data['picture'] ?? '',
              data['invitedBy'] ?? '',
            );
            break;

          case 'group_member_joined':
            for (final listener in List.of(_groupMemberJoinedListeners)) {
              listener(
                data['groupId'],
                data['userId'],
                data['username'] ?? '',
                data['picture'] ?? '',
                data['isContact'] == true,
                (data['memberCount'] as num?)?.toInt() ?? 0,
                data['content'] ?? '',
                data['timestamp'] ?? '',
              );
            }
            break;
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          print('⚠️ /user-socket error: $error — reconnecting');
        }
        _scheduleReconnect();
      },
      onDone: () {
        if (kDebugMode) {
          print('⚠️ /user-socket closed — reconnecting');
        }
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  /// Capped linear backoff (1s, 2s, 3s … up to 10s) — enough to ride out a
  /// brief network blip or backend restart without hammering the server.
  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delaySeconds = _reconnectAttempt.clamp(1, 10);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), connect);
  }

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void sendCallInvite(
    String toUserId,
    String roomId, {
    String callType = 'video',
  }) {
    _send({
      "type": "call_user",
      "from": userId,
      "room": roomId,
      "to": toUserId,
      "call_type": callType,
    });
  }

  void acceptCall(String roomId) {
    _send({"type": "call_accepted", "from": userId, "room": roomId});
  }

  void rejectCall(String callerId) {
    _send({"type": "call_rejected", "from": userId, "to": callerId});
  }

  void cancelCall(String calleeId, String roomId) {
    _send({
      "type": "call_cancelled",
      "from": userId,
      "to": calleeId,
      "room": roomId,
    });
  }

  void sendMessage(String toUserId, String content, String timestamp) {
    _send({
      "type": "chat_message",
      "to": toUserId,
      "from": userId,
      "content": content,
      "timestamp": timestamp,
    });
  }

  void sendTypingStatus(String toUserId, bool isTyping) {
    _send({
      "type": "typing",
      "to": toUserId,
      "from": userId,
      "isTyping": isTyping,
    });
  }

  void sendGroupMessage(String groupId, String content, String timestamp) {
    _send({
      "type": "group_message",
      "groupId": groupId,
      "from": userId,
      "content": content,
      "timestamp": timestamp,
    });
  }

  void sendGroupTypingStatus(String groupId, bool isTyping) {
    _send({
      "type": "group_typing",
      "groupId": groupId,
      "from": userId,
      "isTyping": isTyping,
    });
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
  }
}
