import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:http/http.dart' as http;

class MessageScreen extends StatefulWidget {
  final String currentUserId;
  final User otherUser;
  final UserSocketService userSocket;

  const MessageScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
    required this.userSocket,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();

    _controller.addListener(() {
      setState(() => _canSend = _controller.text.trim().isNotEmpty);
    });

    widget.userSocket.onMessage = (from, content, timestamp) {
      if (from == widget.otherUser.id) {
        setState(() {
          _messages
              .add({'from': from, 'content': content, 'timestamp': timestamp});
        });
        _scrollToBottom();
      }
    };
  }

  Future<void> _fetchChatHistory() async {
    try {
      final uri = Uri.parse(
        'http://${widget.userSocket.serverUrl}/api/users/chat-history?to=${widget.otherUser.id}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.userSocket.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.addAll(data.map<Map<String, String>>((msg) {
            return {
              'from': msg['FromUserID'],
              'content': msg['Content'],
              'timestamp': msg['Timestamp'],
            };
          }).toList());
          _loading = false;
        });
        _scrollToBottom();
      } else {
        debugPrint('❌ Failed to fetch chat history: ${response.body}');
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching chat history: $e');
      setState(() => _loading = false);
    }
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final timestamp = DateTime.now().toIso8601String();

    setState(() {
      _messages.add({
        'from': widget.currentUserId,
        'content': content,
        'timestamp': timestamp,
      });
    });

    widget.userSocket.sendMessage(widget.otherUser.id, content, timestamp);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startCall(String callType) {
    final roomId = '${widget.currentUserId}-${widget.otherUser.id}';
    widget.userSocket.sendCallInvite(
      widget.otherUser.id,
      roomId,
      callType: callType,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          token: widget.userSocket.token,
          roomId: roomId,
          userSocket: widget.userSocket,
          callType: callType,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg) {
    final isMe = msg['from'] == widget.currentUserId;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isMe ? Colors.blue : Colors.grey.shade300;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg['content'] ?? '',
          style: TextStyle(color: textColor, fontSize: 15),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser.username),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'voice') {
                _startCall('audio');
              } else if (value == 'video') {
                _startCall('video');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'voice',
                child: ListTile(
                  leading: Icon(Icons.call),
                  title: Text('Voice Call'),
                ),
              ),
              const PopupMenuItem(
                value: 'video',
                child: ListTile(
                  leading: Icon(Icons.videocam),
                  title: Text('Video Call'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Scrollbar(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
                  ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _canSend
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      color: _canSend ? Colors.white : Colors.black45,
                      onPressed: _canSend ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
