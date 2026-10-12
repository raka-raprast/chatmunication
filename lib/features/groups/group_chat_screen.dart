import 'dart:async';
import 'dart:ui';

import 'package:chatmunication/features/groups/group.dart';
import 'package:chatmunication/features/groups/group_info_screen.dart';
import 'package:chatmunication/features/groups/group_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:chatmunication/shared/ui/components/typing_dots.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class GroupChatScreen extends StatefulWidget {
  final String currentUserId;
  final Group group;
  final int memberCount;
  final UserSocketService userSocket;

  const GroupChatScreen({
    super.key,
    required this.currentUserId,
    required this.group,
    required this.userSocket,
    this.memberCount = 0,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final List<dynamic> _messages = []; // GroupChatMessage or timestamp marker
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, GroupMember> _membersById = {};
  late int _memberCount = widget.memberCount;
  bool _loading = true;
  bool _canSend = false;
  DateTime? _lastMessageDate;
  final Set<String> _typingUserIds = {};
  bool _isTypingSent = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    widget.userSocket.activeGroupId = widget.group.id;
    _loadMembersAndHistory();
    _markAsRead();

    _controller.addListener(_onTextChanged);

    widget.userSocket.addGroupMessageListener(_handleMessage);
    widget.userSocket.addGroupTypingListener(_handleTypingStatus);
    widget.userSocket.addGroupMemberJoinedListener(_handleMemberJoined);
  }

  Future<void> _loadMembersAndHistory() async {
    final service = GroupService(token: widget.userSocket.token);
    try {
      final members = await service.getGroupMembers(widget.group.id);
      final history = await service.getGroupMessages(widget.group.id);
      if (!mounted) return;
      setState(() {
        _membersById = {for (final m in members) m.id: m};
        _memberCount = members.length;
        _lastMessageDate = null;
        for (final msg in history) {
          _addMessageWithDateSeparator(msg);
        }
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _addMessageWithDateSeparator(GroupChatMessage message) {
    final currentMsgDate = message.timestamp;
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

  void _markAsRead() {
    GroupService(token: widget.userSocket.token)
        .markGroupRead(widget.group.id)
        .catchError((_) {});
  }

  void _handleMessage(
    String groupId,
    String fromUserId,
    String content,
    String timestamp,
  ) {
    if (groupId != widget.group.id || !mounted) return;
    setState(() {
      _typingUserIds.remove(fromUserId);
      _addMessageWithDateSeparator(
        GroupChatMessage(
          fromUserId: fromUserId,
          content: content,
          timestamp: DateTime.parse(timestamp),
        ),
      );
    });
    _scrollToBottom();
    _markAsRead();
  }

  /// Live push when someone accepts an invite to this group (see
  /// signaling.BroadcastGroupMemberJoined server-side). Updates the
  /// member map and header count in place and drops a "X joined the
  /// group" system line into the timeline — without this, an already-open
  /// screen keeps a stale member list (new senders render as "Unknown")
  /// and a stale header count until the screen is reopened.
  void _handleMemberJoined(
    String groupId,
    String userId,
    String username,
    String profilePicture,
    bool isContact,
    int memberCount,
    String content,
    String timestamp,
  ) {
    if (groupId != widget.group.id || !mounted) return;
    setState(() {
      _membersById[userId] = GroupMember(
        id: userId,
        username: username,
        profilePicture: profilePicture,
        isCreator: _membersById[userId]?.isCreator ?? false,
        isContact: isContact,
      );
      _memberCount = memberCount;
      _addMessageWithDateSeparator(
        GroupChatMessage(
          fromUserId: userId,
          content: content,
          timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
          isSystem: true,
        ),
      );
    });
    _scrollToBottom();
  }

  void _handleTypingStatus(String groupId, String fromUserId, bool isTyping) {
    if (groupId != widget.group.id || !mounted) return;
    setState(() {
      if (isTyping) {
        _typingUserIds.add(fromUserId);
      } else {
        _typingUserIds.remove(fromUserId);
      }
    });
    if (isTyping) _scrollToBottom();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _canSend) setState(() => _canSend = hasText);

    if (hasText) {
      if (!_isTypingSent) {
        _isTypingSent = true;
        widget.userSocket.sendGroupTypingStatus(widget.group.id, true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _isTypingSent = false;
        widget.userSocket.sendGroupTypingStatus(widget.group.id, false);
      });
    } else {
      _typingTimer?.cancel();
      if (_isTypingSent) {
        _isTypingSent = false;
        widget.userSocket.sendGroupTypingStatus(widget.group.id, false);
      }
    }
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final timestamp = DateTime.now().toIso8601String();

    setState(() {
      _addMessageWithDateSeparator(
        GroupChatMessage(
          fromUserId: widget.currentUserId,
          content: content,
          timestamp: DateTime.parse(timestamp),
        ),
      );
    });

    widget.userSocket.sendGroupMessage(widget.group.id, content, timestamp);
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

  Future<void> _openGroupInfo() async {
    final left = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupInfoScreen(
          currentUserId: widget.currentUserId,
          group: widget.group,
          userSocket: widget.userSocket,
        ),
      ),
    );
    if (left == true && mounted) {
      Navigator.of(context).pop();
    }
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
      return DateFormat.yMMMMd().format(date);
    }
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

  /// WhatsApp-style "X joined the group" line — distinct from a date
  /// pill (italic, muted, translucent) so it doesn't read as a timestamp.
  Widget _buildSystemMessage(String content) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: CMColors.hint,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GroupChatMessage msg) {
    final isMe = msg.fromUserId == widget.currentUserId;
    final sender = _membersById[msg.fromUserId];
    final senderName = sender?.username ?? 'Unknown';
    final textColor = isMe ? Colors.white : CMColors.text;
    final time = DateFormat.Hm().format(msg.timestamp);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group messages, unlike 1:1, don't imply the author — show who
          // sent it above the bubble (skipped for my own messages).
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CMColors.primaryVariant,
                    ),
                  ),
                  if (sender != null && !sender.isContact) ...[
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIconsBold.userCircleMinus,
                      size: 12,
                      color: CMColors.hint,
                    ),
                  ],
                ],
              ),
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 44, bottom: 2),
                child: Text(
                  msg.content,
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
              profilePicture: sender?.profilePicture ?? '',
              email: '',
              username: senderName,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    final names = _typingUserIds
        .map((id) => _membersById[id]?.username ?? 'Someone')
        .join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 36),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$names ',
                  style: TextStyle(fontSize: 12, color: CMColors.hint),
                ),
                const TypingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTypingSent) {
      widget.userSocket.sendGroupTypingStatus(widget.group.id, false);
    }
    if (widget.userSocket.activeGroupId == widget.group.id) {
      widget.userSocket.activeGroupId = null;
    }
    widget.userSocket.removeGroupMessageListener(_handleMessage);
    widget.userSocket.removeGroupTypingListener(_handleTypingStatus);
    widget.userSocket.removeGroupMemberJoinedListener(_handleMemberJoined);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTyping = _typingUserIds.isNotEmpty;

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
            GestureDetector(
              onTap: _openGroupInfo,
              child: CMAvatar(
                size: 40,
                profilePicture: widget.group.picture,
                email: '',
                username: widget.group.name,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        title: GestureDetector(
          onTap: _openGroupInfo,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.group.name,
                overflow: TextOverflow.ellipsis,
                style: CMTextStyle.subtitle.copyWith(
                  color: CMColors.text,
                  fontSize: 16,
                ),
              ),
              if (isTyping)
                Text(
                  'typing...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: CMColors.primaryVariant,
                  ),
                )
              else if (_memberCount > 0)
                Text(
                  '$_memberCount members',
                  style: TextStyle(fontSize: 12, color: CMColors.hint),
                ),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _openGroupInfo,
            child: Container(
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
                    : (_messages.isEmpty && !isTyping)
                    ? Center(child: Text("Say hi to ${widget.group.name}"))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length + (isTyping ? 1 : 0),
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: 102 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingBubble();
                          }
                          final msg = _messages[index];
                          if (msg is Map && msg['type'] == 'timestamp') {
                            return _buildDateSeparator(msg['label'] as String);
                          }
                          final chatMsg = msg as GroupChatMessage;
                          return chatMsg.isSystem
                              ? _buildSystemMessage(chatMsg.content)
                              : _buildMessageBubble(chatMsg);
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
}
