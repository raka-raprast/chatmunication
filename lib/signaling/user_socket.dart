import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class UserSocketService {
  static final UserSocketService instance = UserSocketService._internal();

  // Private constructor
  UserSocketService._internal();

  // Call `init(...)` once before using
  late String token;
  late String userId;
  late String serverUrl;

  late void Function(
    String fromUserId,
    String roomId,
    String fromName,
    String profilePicture,
    String callType,
  ) onIncomingCall;

  late void Function(String roomId) onCallAccepted;
  late void Function() onCallRejected;
  void Function()? onCallCancelled;
  void Function(String fromUserId, String content, String timestamp)? onMessage;
  void Function(String userId, bool isOnline)? onOnlineStatusChanged;
  void Function(List<String> onlineUserIds)? onInitialOnlineUsers;

  late WebSocketChannel _channel;

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
    ) onIncomingCall,
    required void Function(String roomId) onCallAccepted,
    required void Function() onCallRejected,
    void Function()? onCallCancelled,
    void Function(String fromUserId, String content, String timestamp)?
        onMessage,
    void Function(String userId, bool isOnline)? onOnlineStatusChanged,
    void Function(List<String> onlineUserIds)? onInitialOnlineUsers,
  }) {
    this.token = token;
    this.userId = userId;
    this.serverUrl = serverUrl;
    this.onIncomingCall = onIncomingCall;
    this.onCallAccepted = onCallAccepted;
    this.onCallRejected = onCallRejected;
    this.onCallCancelled = onCallCancelled;
    this.onMessage = onMessage;
    this.onOnlineStatusChanged = onOnlineStatusChanged;
    this.onInitialOnlineUsers = onInitialOnlineUsers;
  }

  void connect() {
    final uri = Uri.parse('ws://$serverUrl/user-socket?userId=$userId');
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen((event) {
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
          onMessage?.call(data['from'], data['content'], data['timestamp']);
          break;
      }
    });
  }

  void sendCallInvite(String toUserId, String roomId,
      {String callType = 'video'}) {
    final msg = {
      "type": "call_user",
      "from": userId,
      "room": roomId,
      "to": toUserId,
      "call_type": callType,
    };
    _channel.sink.add(jsonEncode(msg));
  }

  void acceptCall(String roomId) {
    _channel.sink.add(jsonEncode({
      "type": "call_accepted",
      "from": userId,
      "room": roomId,
    }));
  }

  void rejectCall(String callerId) {
    _channel.sink.add(jsonEncode({
      "type": "call_rejected",
      "from": userId,
      "to": callerId,
    }));
  }

  void cancelCall(String calleeId, String roomId) {
    _channel.sink.add(jsonEncode({
      "type": "call_cancelled",
      "from": userId,
      "to": calleeId,
      "room": roomId,
    }));
  }

  void sendMessage(String toUserId, String content, String timestamp) {
    _channel.sink.add(jsonEncode({
      "type": "chat_message",
      "to": toUserId,
      "from": userId,
      "content": content,
      "timestamp": timestamp,
    }));
  }

  void dispose() {
    _channel.sink.close();
  }
}
