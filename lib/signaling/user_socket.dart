import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_channel/web_socket_channel.dart';

class UserSocketService {
  final String token;
  final String userId;
  final String serverUrl;

  void Function(String fromUserId, String roomId, String fromName,
      String profilePicture, String callType) onIncomingCall;
  void Function(String roomId) onCallAccepted;
  void Function() onCallRejected;
  void Function(String fromUserId, String content, String timestamp)? onMessage;

  late WebSocketChannel _channel;

  UserSocketService({
    required this.serverUrl,
    required this.token,
    required this.userId,
    required this.onIncomingCall,
    required this.onCallAccepted,
    required this.onCallRejected,
    this.onMessage, // ✅ add this
  });

  void connect() {
    final uri = Uri.parse('ws://$serverUrl/user-socket?userId=$userId');
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen((event) {
      final data = jsonDecode(event);
      final type = data['type'];
      log(data.toString());
      if (type == 'incoming_call') {
        final from = data['from'];
        final room = data['room'];
        final username = data['username'];
        final profilePicture = data['profile_picture'];
        final callType = data['call_type'];
        onIncomingCall(from, room, username, profilePicture, callType);
      } else if (type == 'call_accepted') {
        final room = data['room'];
        onCallAccepted(room);
      } else if (type == 'call_rejected') {
        onCallRejected();
      } else if (type == 'chat_message') {
        final from = data['from'];
        final content = data['content'];
        final timestamp = data['timestamp'];
        onMessage?.call(from, content, timestamp);
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
    final msg = {
      "type": "call_accepted",
      "from": userId,
      "room": roomId,
    };
    _channel.sink.add(jsonEncode(msg));
  }

  void rejectCall(String callerId) {
    final msg = {
      "type": "call_rejected",
      "from": userId, // this is callee
      "to": callerId, // ✅ this is caller!
    };
    _channel.sink.add(jsonEncode(msg));
  }

  void sendMessage(String toUserId, String content, String timestamp) {
    final msg = {
      "type": "chat_message",
      "to": toUserId,
      "from": userId,
      "content": content,
      "timestamp": timestamp,
    };
    _channel.sink.add(jsonEncode(msg));
  }

  void dispose() {
    _channel.sink.close();
  }
}
