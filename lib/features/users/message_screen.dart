import 'dart:convert';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/back_button.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  final List<dynamic> _messages = []; // can be message or timestamp marker
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  bool _canSend = false;
  DateTime? _lastMessageDate;

  void _addMessageWithDateSeparator(Map<String, String> message) {
    final currentMsgDate = DateTime.parse(message['timestamp']!);
    final dateLabel = getDateLabel(currentMsgDate);

    if (_lastMessageDate == null ||
        _lastMessageDate!.year != currentMsgDate.year ||
        _lastMessageDate!.month != currentMsgDate.month ||
        _lastMessageDate!.day != currentMsgDate.day) {
      _messages.add({'type': 'timestamp', 'label': dateLabel});
      _lastMessageDate = currentMsgDate;
    }

    _messages.add(message);
  }

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
          _lastMessageDate = null;
          for (var msg in data) {
            _addMessageWithDateSeparator({
              'from': msg['FromUserID'],
              'content': msg['Content'],
              'timestamp': msg['Timestamp'],
            });
          }

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
      _addMessageWithDateSeparator({
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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CallScreen(
          token: widget.userSocket.token,
          roomId: roomId,
          userSocket: widget.userSocket,
          callType: callType,
          otherUser: widget.otherUser,
          isCaller: true,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildDateSeparator(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: CMColors.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: CMTextStyle.text,
        ),
      ),
    );
  }

  String getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMMd().format(date); // Example: June 24, 2025
    }
  }

  Widget _buildMessageBubble(Map<String, String> msg) {
    final isMe = msg['from'] == widget.currentUserId;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isMe ? CMColors.primaryVariant : Colors.white;
    final textColor = isMe ? Colors.white : CMColors.text;

    final time = DateFormat.Hm()
        .format(DateTime.parse(msg['timestamp']!)); // e.g., 13:05

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(999),
            bottomRight: Radius.circular(isMe ? 0 : 999),
            bottomLeft: Radius.circular(isMe ? 999 : 0),
            topLeft: Radius.circular(999),
          ),
          border: isMe
              ? null
              : Border.all(
                  width: .5,
                  color: CMColors.primaryVariant,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: .7),
                  ),
                ),
              ),
              SizedBox(
                width: 6,
              )
            ],
            Text(
              msg['content'] ?? '',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
              ),
            ),
            if (isMe) ...[
              SizedBox(
                width: 6,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: .7),
                  ),
                ),
              )
            ],
          ],
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
    return CMScaffold(
      useGradientBackground: false,
      floatingAppBar: CMFloatingAppBar(
        leading: Row(
          children: [
            CMBackButton(),
            CMAvatar(
              size: 45,
              profilePicture: widget.otherUser.profilePicture,
              email: widget.otherUser.email ?? '',
              username: widget.otherUser.username,
            ),
            SizedBox(
              width: 6,
            ),
            Text(
              widget.otherUser.username,
              style: CMTextStyle.subtitle.copyWith(color: CMColors.text),
            )
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _startCall('video'),
            child: Icon(
              CupertinoIcons.video_camera_solid,
              color: CMColors.primaryVariant,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          GestureDetector(
            onTap: () => _startCall('audio'),
            child: Icon(
              Icons.call,
              color: CMColors.primaryVariant,
            ),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: true,
            child: Stack(
              children: [
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Scrollbar(
                        child: _messages.isEmpty
                            ? Center(
                                child: Text(
                                    "Say something to ${widget.otherUser.username}"),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: _messages.length,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10) +
                                        EdgeInsets.only(
                                            bottom: kToolbarHeight * 1.5),
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  if (_messages[index] is Map<String, String> &&
                                      _messages[index]['type'] == 'timestamp') {
                                    return _buildDateSeparator(
                                        _messages[index]['label']!);
                                  } else {
                                    return _buildMessageBubble(_messages[index]
                                        as Map<String, String>);
                                  }
                                },
                              ),
                      ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      height: kToolbarHeight + 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 5,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: kBottomNavigationBarHeight * 1.1,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white,
                          gradient: LinearGradient(colors: [
                            CMColors.primary.withValues(alpha: .1),
                            CMColors.primaryVariant.withValues(alpha: .15),
                          ]),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CMTextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 7,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                label: 'Type a message...',
                                radius: 999,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send),
                              color: _canSend
                                  ? CMColors.primaryVariant
                                  : CMColors.hint,
                              onPressed: _canSend ? _sendMessage : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
