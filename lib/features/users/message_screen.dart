import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/profile_widget.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:chatmunication/shared/ui/components/typing_dots.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MessageScreen extends StatefulWidget {
  final String currentUserId;
  final User otherUser;
  final UserSocketService userSocket;
  final bool isOnline;

  const MessageScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
    required this.userSocket,
    this.isOnline = false,
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
  bool _otherUserTyping = false;
  bool _isTypingSent = false;
  Timer? _typingTimer;

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
    widget.userSocket.activeChatUserId = widget.otherUser.id;
    _fetchChatHistory();
    _markAsRead();

    _controller.addListener(_onTextChanged);

    widget.userSocket.addMessageListener(_handleMessage);
    widget.userSocket.addTypingListener(_handleTypingStatus);
  }

  /// Tells the server every message from this contact has been seen. Fired
  /// on open (covers history) and again whenever a new message arrives
  /// while the chat stays open, so the unread count the chat list reads
  /// back later is always accurate.
  void _markAsRead() {
    UserService(token: widget.userSocket.token)
        .markMessagesRead(widget.otherUser.id)
        .catchError((_) {});
  }

  void _handleMessage(String from, String content, String timestamp) {
    if (from != widget.otherUser.id || !mounted) return;
    setState(() {
      _otherUserTyping = false;
      _messages.add({'from': from, 'content': content, 'timestamp': timestamp});
    });
    _scrollToBottom();
    _markAsRead();
  }

  void _handleTypingStatus(String fromUserId, bool isTyping) {
    if (fromUserId != widget.otherUser.id || !mounted) return;
    setState(() => _otherUserTyping = isTyping);
    if (isTyping) _scrollToBottom();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _canSend) setState(() => _canSend = hasText);

    if (hasText) {
      if (!_isTypingSent) {
        _isTypingSent = true;
        widget.userSocket.sendTypingStatus(widget.otherUser.id, true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _isTypingSent = false;
        widget.userSocket.sendTypingStatus(widget.otherUser.id, false);
      });
    } else {
      _typingTimer?.cancel();
      if (_isTypingSent) {
        _isTypingSent = false;
        widget.userSocket.sendTypingStatus(widget.otherUser.id, false);
      }
    }
  }

  Future<void> _fetchChatHistory() async {
    try {
      final uri = Uri.parse(
        'http://${widget.userSocket.serverUrl}/api/users/chat-history?to=${widget.otherUser.id}',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.userSocket.token}'},
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

  void _viewProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          token: widget.userSocket.token,
          profileId: widget.otherUser.id,
          currentUserId: widget.currentUserId,
        ),
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
        child: Text(label, style: CMTextStyle.text),
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
    final textColor = isMe ? Colors.white : CMColors.text;
    final time = DateFormat.Hm().format(
      DateTime.parse(msg['timestamp']!),
    ); // e.g., 13:05

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4C94F7), Color(0xFF3C7FF6)],
              )
            : null,
        color: isMe ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Reserve a fixed corner on every line so the timestamp always
          // anchors to the same spot, instead of trailing wherever the
          // text happens to wrap.
          Padding(
            padding: const EdgeInsets.only(right: 44, bottom: 2),
            child: Text(
              msg['content'] ?? '',
              softWrap: true,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: .65),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CMAvatar(
              size: 28,
              profilePicture: widget.otherUser.profilePicture,
              email: widget.otherUser.email ?? '',
              username: widget.otherUser.username,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CMAvatar(
            size: 28,
            profilePicture: widget.otherUser.profilePicture,
            email: widget.otherUser.email ?? '',
            username: widget.otherUser.username,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TypingDots(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTypingSent) {
      widget.userSocket.sendTypingStatus(widget.otherUser.id, false);
    }
    if (widget.userSocket.activeChatUserId == widget.otherUser.id) {
      widget.userSocket.activeChatUserId = null;
    }
    widget.userSocket.removeMessageListener(_handleMessage);
    widget.userSocket.removeTypingListener(_handleTypingStatus);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CMScaffold(
      backgroundImage: 'lib/assets/images/onboarding_background.jpg',
      floatingAppBar: CMFloatingAppBar(
        isTransparent: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.caretLeft,
                  color: CMColors.text,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CMAvatar(
                  size: 40,
                  profilePicture: widget.otherUser.profilePicture,
                  email: widget.otherUser.email ?? '',
                  username: widget.otherUser.username,
                ),
                if (widget.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUser.username,
              overflow: TextOverflow.ellipsis,
              style: CMTextStyle.subtitle.copyWith(
                color: CMColors.text,
                fontSize: 16,
              ),
            ),
            if (_otherUserTyping)
              Text(
                'typing...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: CMColors.primaryVariant,
                ),
              )
            else if (widget.isOnline)
              Text(
                'Online',
                style: TextStyle(fontSize: 12, color: CMColors.primaryVariant),
              ),
          ],
        ),
        actions: [
          _headerIconButton(
            icon: PhosphorIconsFill.videoCamera,
            onTap: () => _startCall('video'),
          ),
          const SizedBox(width: 8),
          _headerIconButton(
            icon: PhosphorIconsFill.phone,
            onTap: () => _startCall('audio'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            color: Colors.white,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsBold.dotsThreeVertical,
                color: CMColors.text,
                size: 18,
              ),
            ),
            onSelected: (value) {
              if (value == 'profile') _viewProfile();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.userCircle,
                      color: CMColors.primaryVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'View Profile',
                      style: TextStyle(
                        color: CMColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                    : (_messages.isEmpty && !_otherUserTyping)
                    ? Center(
                        child: Text(
                          "Say something to ${widget.otherUser.username}",
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            _messages.length + (_otherUserTyping ? 1 : 0),
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: 102 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingBubble();
                          }
                          final msg = _messages[index];
                          if (msg is Map<String, String> &&
                              msg['type'] == 'timestamp') {
                            return _buildDateSeparator(msg['label']!);
                          }
                          return _buildMessageBubble(
                            msg as Map<String, String>,
                          );
                        },
                      ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.only(top: 28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.85),
                            ],
                            stops: const [0, 0.35],
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: CMTextField(
                                    controller: _controller,
                                    minLines: 1,
                                    maxLines: 6,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    label: 'Type a message...',
                                    radius: 999,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _canSend ? _sendMessage : null,
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: _canSend
                                          ? const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF4C94F7),
                                                Color(0xFF3C7FF6),
                                              ],
                                            )
                                          : null,
                                      color: _canSend
                                          ? null
                                          : CMColors.hint.withValues(alpha: .3),
                                    ),
                                    child: const Icon(
                                      PhosphorIconsFill.paperPlaneRight,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: CMColors.primaryVariant, size: 18),
      ),
    );
  }
}
