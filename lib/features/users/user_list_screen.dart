import 'dart:convert';
import 'dart:developer';

import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/incoming_call_screen.dart';
import 'package:chatmunication/features/users/message_screen.dart';
import 'package:chatmunication/features/users/profile_widget.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/groups/group.dart';
import 'package:chatmunication/features/groups/group_chat_screen.dart';
import 'package:chatmunication/features/groups/group_service.dart';
import 'package:chatmunication/features/groups/create_group_screen.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/features/users/search_screen.dart';
import 'package:chatmunication/features/users/requests_screen.dart';
import 'package:chatmunication/features/users/widgets/chat_list_header.dart';
import 'package:chatmunication/shared/ui/components/floating_action_menu.dart';
import 'package:chatmunication/features/users/widgets/chat_list_tile.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/nav_bar_item.dart';
import 'package:chatmunication/shared/config/app_config.dart';
import 'package:chatmunication/shared/fcm.dart';
import 'package:chatmunication/shared/in_app_notification.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single row in the "All"/"Unread" chat feed — either a 1:1 chat or a
/// group, normalized so they can be merged and sorted by last activity
/// together (WhatsApp-style combined list), rather than groups only ever
/// showing up under their own separate "Groups" filter.
class _ChatListEntry {
  final UserWithLastMessage? user;
  final GroupWithLastMessage? group;

  _ChatListEntry.user(this.user) : group = null;
  _ChatListEntry.group(this.group) : user = null;

  DateTime get sortTime =>
      user?.lastMessageTimestamp ??
      group?.lastMessageTimestamp ??
      DateTime.fromMillisecondsSinceEpoch(0);

  int get unreadCount => user?.unreadCount ?? group?.unreadCount ?? 0;

  Widget build(_UserListScreenState state) {
    return user != null
        ? state._buildUserItem(user: user!)
        : state._buildGroupItem(group: group!);
  }
}

class UserListScreen extends StatefulWidget {
  final String token;
  final String userId;

  const UserListScreen({required this.token, required this.userId});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final userSocket = UserSocketService.instance;
  late Future<User> _profileFuture;
  bool isVideoCall = true;
  bool _isInCallScreen = false;
  final Map<String, bool> onlineUsers = {};
  final Map<String, bool> _onlineStatus = {};

  int _selectedIndex = 0;
  ChatFilter _selectedFilter = ChatFilter.all;
  List<UserWithLastMessage> _cachedUsers = [];
  bool _usersLoading = true;
  Object? _usersError;
  final Set<String> _typingUserIds = {};

  List<GroupWithLastMessage> _cachedGroups = [];
  bool _groupsLoading = true;
  Object? _groupsError;
  final Set<String> _groupTypingIds = {};

  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadGroups();
    _loadPendingRequestsCount();
    // `catchError` here is purely to mark this future as "observed" so
    // Dart's zone doesn't log a spurious "Unhandled Exception" for it —
    // the Profile tab's own `FutureBuilder` (which attaches its own,
    // real listener only once that tab is actually built/visible) still
    // gets and handles the same error normally via `snapshot.error`.
    _profileFuture = _fetchProfile()
      ..catchError((_) => User(id: '', username: '', profilePicture: ''));

    userSocket.init(
      serverUrl: AppConfig.wsBaseUrl,
      token: widget.token,
      userId: widget.userId,
      onIncomingCall: _onIncomingCall,
      onCallAccepted: _onCallAccepted,
      onCallRejected: _onCallRejected,
      onOnlineStatusChanged: (userId, isOnline) {
        setState(() {
          _onlineStatus[userId] = isOnline;
        });
      },
      onInitialOnlineUsers: (onlineUserIds) {
        setState(() {
          for (var id in onlineUserIds) {
            _onlineStatus[id] = true;
          }
        });
      },
      onCallCancelled: () {
        Navigator.pop(context);
      },
      onGroupInvite: _handleGroupInvite,
    );
    userSocket.connect();
    userSocket.addMessageListener(_handleIncomingMessage);
    userSocket.addTypingListener(_handleTypingStatus);
    userSocket.addGroupMessageListener(_handleIncomingGroupMessage);
    userSocket.addGroupTypingListener(_handleGroupTypingStatus);
    _registerFcmToken();
  }

  /// Sends this device's FCM token to the server so it can push a
  /// notification for calls/messages received while the socket isn't
  /// connected (backgrounded or killed app).
  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await getFcmToken();
      if (fcmToken == null) return;
      await UserService(token: widget.token)
          .updateFcmToken(widget.userId, fcmToken);
    } catch (_) {
      // Best-effort — push notifications just won't work for this session.
    }
  }

  /// Combined count of incoming friend requests + pending group invites —
  /// drives the chat list bell's badge.
  Future<void> _loadPendingRequestsCount() async {
    try {
      final results = await Future.wait([
        UserService(token: widget.token).getIncomingContactRequests(),
        GroupService(token: widget.token).getGroupInvites(),
      ]);
      if (!mounted) return;
      setState(() {
        _pendingRequestsCount =
            (results[0] as List).length + (results[1] as List).length;
      });
    } catch (_) {
      // Best-effort — badge just stays at its last known value.
    }
  }

  void _openRequests() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RequestsScreen(token: widget.token)),
    );
    _loadPendingRequestsCount();
    _loadUsers(showSpinner: false);
    _loadGroups(showSpinner: false);
  }

  /// Patches the affected conversation in place and bumps it to the top —
  /// no network round-trip, no full-list reload. A WebSocket push already
  /// carries everything needed to update the list; re-fetching from the
  /// server on every message defeats the point of having a socket.
  void _handleIncomingMessage(String from, String content, String timestamp) {
    if (!mounted) return;

    final index = _cachedUsers.indexWhere((u) => u.id == from);
    if (index == -1) {
      // First-ever message from a sender not yet in the cached list (e.g. a
      // brand-new contact). Only this cold-start edge case needs a real
      // fetch, and even then without flashing the spinner over an
      // already-populated list.
      _loadUsers(showSpinner: false);
      return;
    }

    final isChatOpen = userSocket.activeChatUserId == from;
    final sender = _cachedUsers[index];

    setState(() {
      _typingUserIds.remove(from);
      final updated = sender.copyWith(
        lastMessageContent: content,
        lastMessageTimestamp: DateTime.parse(timestamp),
        isSender: false,
        unreadCount: isChatOpen ? 0 : sender.unreadCount + 1,
      );
      _cachedUsers = [updated, ..._cachedUsers.where((u) => u.id != from)];
    });

    if (!isChatOpen) {
      InAppNotificationBanner.show(
        title: sender.username,
        message: content,
        profilePicture: sender.profilePicture,
        onTap: () => _startChat(
          User(
            id: sender.id,
            username: sender.username,
            profilePicture: sender.profilePicture,
            email: sender.email,
          ),
        ),
      );
    }
  }

  /// Live push for a brand-new group invite (see
  /// signaling.SendGroupInvite server-side) — bumps the bell badge
  /// immediately and surfaces who invited the user to which group,
  /// instead of only finding out next time the chat list is reloaded.
  void _handleGroupInvite(
    String inviteId,
    String groupId,
    String groupName,
    String picture,
    String invitedBy,
  ) {
    if (!mounted) return;
    setState(() => _pendingRequestsCount += 1);
    InAppNotificationBanner.show(
      title: invitedBy,
      message: 'Invited you to "$groupName"',
      profilePicture: picture,
      onTap: _openRequests,
    );
  }

  void _handleTypingStatus(String fromUserId, bool isTyping) {
    if (!mounted) return;
    if (_typingUserIds.contains(fromUserId) == isTyping) return;
    setState(() {
      if (isTyping) {
        _typingUserIds.add(fromUserId);
      } else {
        _typingUserIds.remove(fromUserId);
      }
    });
  }

  Future<void> _loadUsers({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _usersLoading = true;
        _usersError = null;
      });
    }
    try {
      final users = await UserService(token: widget.token)
          .getUsersWithLastMessage();
      if (mounted) {
        setState(() {
          _cachedUsers = users;
          _usersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usersError = e;
          _usersLoading = false;
        });
      }
    }
  }

  Future<void> _loadGroups({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _groupsLoading = true;
        _groupsError = null;
      });
    }
    try {
      final groups = await GroupService(token: widget.token).getUserGroups();
      if (mounted) {
        setState(() {
          _cachedGroups = groups;
          _groupsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _groupsError = e;
          _groupsLoading = false;
        });
      }
    }
  }

  void _handleIncomingGroupMessage(
    String groupId,
    String fromUserId,
    String content,
    String timestamp,
  ) {
    if (!mounted) return;

    final index = _cachedGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) {
      // A group we don't have cached yet — either just created/added to
      // elsewhere, or a cold start. Either way a real fetch is needed.
      _loadGroups(showSpinner: false);
      return;
    }

    final isGroupOpen = userSocket.activeGroupId == groupId;
    final group = _cachedGroups[index];
    final senderName = fromUserId == widget.userId
        ? 'You'
        : (_groupMemberName(fromUserId) ?? 'Someone');

    setState(() {
      _groupTypingIds.remove(groupId);
      final updated = group.copyWith(
        lastMessageContent: content,
        lastMessageSenderName: senderName,
        lastMessageTimestamp: DateTime.parse(timestamp),
        isSender: fromUserId == widget.userId,
        unreadCount: isGroupOpen ? 0 : group.unreadCount + 1,
      );
      _cachedGroups = [updated, ..._cachedGroups.where((g) => g.id != groupId)];
    });

    if (!isGroupOpen && fromUserId != widget.userId) {
      InAppNotificationBanner.show(
        title: '${group.name} · $senderName',
        message: content,
        profilePicture: group.picture,
        onTap: () => _openGroup(group),
      );
    }
  }

  /// Best-effort sender display name for a group-message banner/preview —
  /// `_cachedGroups` doesn't carry a member roster, so this only resolves
  /// if we happen to already know the sender as a 1:1 contact. Falls back
  /// to a generic label otherwise rather than guessing.
  String? _groupMemberName(String userId) {
    final match = _cachedUsers.where((u) => u.id == userId);
    return match.isEmpty ? null : match.first.username;
  }

  void _handleGroupTypingStatus(
    String groupId,
    String fromUserId,
    bool isTyping,
  ) {
    if (!mounted) return;
    if (_groupTypingIds.contains(groupId) == isTyping) return;
    setState(() {
      if (isTyping) {
        _groupTypingIds.add(groupId);
      } else {
        _groupTypingIds.remove(groupId);
      }
    });
  }

  void _onIncomingCall(
    String fromUserId,
    String roomId,
    String fromName,
    String profilePicture,
    String callType,
  ) {
    setState(() => isVideoCall = callType == 'video');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerId: fromUserId,
          roomId: roomId,
          token: widget.token,
          fromName: fromName,
          userSocket: userSocket,
          profilePicture: profilePicture,
          callType: callType,
        ),
      ),
    );
  }

  void _onCallAccepted(String roomId) {
    _isInCallScreen = true;
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => CallScreen(
              token: widget.token,
              roomId: roomId,
              userSocket: userSocket,
              callType: isVideoCall ? 'video' : 'audio',
              isCaller: false,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        )
        .then((_) => _isInCallScreen = false);
  }

  /// On a genuine network/server error, lets the Profile tab's
  /// `FutureBuilder` show its "Retry" affordance (unchanged). On 401
  /// (missing/expired/invalid-signature token — `JWTAuthMiddleware`) or
  /// 404 (a validly-signed token whose `user_id` no longer exists —
  /// `Me()` itself, after the middleware passes), though, retrying is
  /// pointless: the stored session can never resolve to a real logged-in
  /// user against whatever backend this build is pointed at. The 404
  /// case is exactly what happens after switching `AppConfig`'s target
  /// backend (or DB) out from under an already-cached session — fail
  /// that out to a hard logout instead of leaving the user stuck on a
  /// screen whose profile tab (and `/user-socket` connection, which
  /// hits this same "unknown user" wall and reconnect-loops forever)
  /// can never recover without a fresh login.
  Future<User> _fetchProfile() async {
    final response = await http.get(
      Uri.parse('${AppConfig.authBaseUrl}/me'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 401 || response.statusCode == 404) {
      if (mounted) _logout();
      throw Exception('Session expired');
    }
    throw Exception('Failed to load profile');
  }

  void _onCallRejected() {
    if (_isInCallScreen) {
      Navigator.pop(context);
      _isInCallScreen = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Call was rejected."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startCall(User user, {required String callType}) {
    final roomId = '${widget.userId}-${user.id}';
    setState(() => isVideoCall = callType == 'video');

    userSocket.sendCallInvite(user.id, roomId, callType: callType);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CallScreen(
          token: widget.token,
          roomId: roomId,
          userSocket: userSocket,
          callType: callType,
          otherUser: user,
          isCaller: true,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _startChat(User user) async {
    // Optimistic: zero the badge the instant the chat is opened rather
    // than waiting for the server round-trip on return.
    final index = _cachedUsers.indexWhere((u) => u.id == user.id);
    if (index != -1 && _cachedUsers[index].unreadCount > 0) {
      setState(() {
        _cachedUsers[index] = _cachedUsers[index].copyWith(unreadCount: 0);
      });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          currentUserId: widget.userId,
          otherUser: user,
          userSocket: userSocket,
          isOnline: _onlineStatus[user.id] == true,
        ),
      ),
    );

    // Refresh user list after returning from chat (silent — list is
    // already live via the socket, this just catches anything missed).
    _loadUsers(showSpinner: false);
  }

  void _openGroup(GroupWithLastMessage group) async {
    final index = _cachedGroups.indexWhere((g) => g.id == group.id);
    if (index != -1 && _cachedGroups[index].unreadCount > 0) {
      setState(() {
        _cachedGroups[index] = _cachedGroups[index].copyWith(unreadCount: 0);
      });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(
          currentUserId: widget.userId,
          group: Group(
            id: group.id,
            name: group.name,
            picture: group.picture,
            createdBy: group.createdBy,
          ),
          memberCount: group.memberCount,
          userSocket: userSocket,
        ),
      ),
    );

    _loadGroups(showSpinner: false);
  }

  void _openCreateGroup() async {
    final created = await Navigator.push<Group>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(
          token: widget.token,
          currentUserId: widget.userId,
        ),
      ),
    );
    if (created == null) return;

    await _loadGroups(showSpinner: false);
    if (!mounted) return;

    final cached = _cachedGroups.firstWhere(
      (g) => g.id == created.id,
      orElse: () => GroupWithLastMessage(
        id: created.id,
        name: created.name,
        picture: created.picture,
        createdBy: created.createdBy,
      ),
    );
    _openGroup(cached);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> _shareProfile(User profile) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Add me on Chatmunication!\n'
            'Username: ${profile.username}\n'
            'User ID: ${profile.id}',
      ),
    );
  }

  void _showEditProfileComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile editing isn't available yet."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(date); // e.g. 14:15
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (today.difference(messageDate).inDays < 7) {
      return DateFormat.E().format(date); // e.g. Mon, Tue, Wed
    } else {
      return DateFormat.yMMMMd().format(date); // e.g. June 24, 2025
    }
  }

  @override
  void dispose() {
    userSocket.removeMessageListener(_handleIncomingMessage);
    userSocket.removeTypingListener(_handleTypingStatus);
    userSocket.removeGroupMessageListener(_handleIncomingGroupMessage);
    userSocket.removeGroupTypingListener(_handleGroupTypingStatus);
    userSocket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread =
        _cachedUsers.any((u) => u.unreadCount > 0) ||
        _cachedGroups.any((g) => g.unreadCount > 0);

    return CMScaffold(
      backgroundImage: 'lib/assets/images/onboarding_background.jpg',
      floatingAppBar: _selectedIndex == 0
          ? ChatListHeader(
              key: const ValueKey('chatListHeader'),
              onSearchTap: _openSearch,
              selectedFilter: _selectedFilter,
              hasUnread: hasUnread,
              pendingRequestsCount: _pendingRequestsCount,
              onBellTap: _openRequests,
              onFilterChanged: (filter) =>
                  setState(() => _selectedFilter = filter),
            )
          : CMFloatingAppBar(
              key: const ValueKey('general'),
              isTransparent: true,
              title: Center(
                child: Text(
                  'Profile',
                  style: CMTextStyle.subtitle.copyWith(color: CMColors.text),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsBold.signOut,
                      color: CMColors.primaryVariant,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
      body: CustomScrollView(
        slivers: _selectedIndex == 0 ? _buildChatList() : _buildProfileTab(),
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: _selectedIndex == 0 ? _buildComposeButton() : null,
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SearchScreen(token: widget.token, currentUserId: widget.userId),
      ),
    ).then((_) => _loadUsers(showSpinner: false));
  }

  /// On the Groups filter, the compose action creates a new group;
  /// everywhere else it opens search to start a 1:1 chat.
  Widget _buildComposeButton() {
    final isGroupsTab = _selectedFilter == ChatFilter.groups;
    return GestureDetector(
      onTap: isGroupsTab ? _openCreateGroup : _openSearch,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C94F7), Color(0xFF3C7FF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: CMColors.primaryVariant.withValues(alpha: .35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isGroupsTab
              ? PhosphorIconsBold.usersThree
              : PhosphorIconsBold.pencilSimpleLine,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNavBar() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: LinearGradient(
        colors: [
          CMColors.primary.withValues(alpha: .1),
          CMColors.primaryVariant.withValues(alpha: .15),
        ],
      ),
    ),
    height: kBottomNavigationBarHeight,
    child: Row(
      children: [
        NavBarItem(
          icon: PhosphorIconsRegular.chatCircle,
          selectedIcon: PhosphorIconsFill.chatCircle,
          label: 'Chats',
          isSelected: _selectedIndex == 0,
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        NavBarItem(
          icon: PhosphorIconsRegular.user,
          selectedIcon: PhosphorIconsFill.user,
          label: 'Profile',
          isSelected: _selectedIndex == 1,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
      ],
    ),
  );

  List<Widget> _buildChatList() {
    return [
      if (_selectedFilter == ChatFilter.groups)
        _buildGroupsSliver()
      else if (_selectedFilter == ChatFilter.favorites)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                "No favorites yet",
                style: TextStyle(color: CMColors.hint),
              ),
            ),
          ),
        )
      else
        _buildChatsSliver(),
    ];
  }

  Widget _buildChatsSliver() {
    if (_usersLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: SpinKitFoldingCube(color: CMColors.surface, size: 40.0),
        ),
      );
    }
    if (_usersError != null) {
      return SliverToBoxAdapter(child: Center(child: Text('⚠️ $_usersError')));
    }

    // "All"/"Unread" mix 1:1 chats and groups into one WhatsApp-style
    // feed sorted by last activity — the "Groups" filter still shows
    // groups on their own via _buildGroupsSliver.
    final entries = <_ChatListEntry>[
      ..._cachedUsers.map(_ChatListEntry.user),
      ..._cachedGroups.map(_ChatListEntry.group),
    ]..sort((a, b) => b.sortTime.compareTo(a.sortTime));

    final visible = _selectedFilter == ChatFilter.unread
        ? entries.where((e) => e.unreadCount > 0).toList()
        : entries;

    if (visible.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Text(
            _selectedFilter == ChatFilter.unread
                ? "No unread chats"
                : "No chats yet",
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("Chats", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...visible.map((e) => e.build(this)),
      ]),
    );
  }

  Widget _buildUserItem({required UserWithLastMessage user}) {
    final id = user.id;
    final username = user.username;
    final email = user.email ?? '';
    final profilePicture = user.profilePicture;
    final lastMessage = user.lastMessageContent;
    final lastTimestamp = user.lastMessageTimestamp;

    return ChatListTile(
      username: username,
      email: email,
      profilePicture: profilePicture,
      isOnline: _onlineStatus[id] == true,
      isTyping: _typingUserIds.contains(id),
      lastMessage: lastMessage,
      timestampLabel: lastTimestamp != null
          ? getDateLabel(lastTimestamp)
          : null,
      unreadCount: user.unreadCount,
      onTap: () => _startChat(
        User(
          id: id,
          username: username,
          profilePicture: profilePicture,
          email: email,
        ),
      ),
      onLongPress: (topLeft, size) =>
          _showCallDialog(user, anchorTopLeft: topLeft, anchorSize: size),
    );
  }

  Widget _buildGroupsSliver() {
    if (_groupsLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: SpinKitFoldingCube(color: CMColors.surface, size: 40.0),
        ),
      );
    }
    if (_groupsError != null) {
      return SliverToBoxAdapter(child: Center(child: Text('⚠️ $_groupsError')));
    }
    if (_cachedGroups.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "No groups yet",
                  style: TextStyle(color: CMColors.hint),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _openCreateGroup,
                  icon: const Icon(
                    PhosphorIconsBold.usersThree,
                    size: 16,
                    color: CMColors.primaryVariant,
                  ),
                  label: const Text(
                    'Create a group',
                    style: TextStyle(color: CMColors.primaryVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("Groups", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ..._cachedGroups.map((g) => _buildGroupItem(group: g)),
      ]),
    );
  }

  Widget _buildGroupItem({required GroupWithLastMessage group}) {
    final lastMessage = group.lastMessageContent;
    final preview = (lastMessage == null || group.lastMessageIsSystem)
        ? lastMessage
        : (group.isSender != true
              ? '${group.lastMessageSenderName ?? "Someone"}: $lastMessage'
              : lastMessage);

    return ChatListTile(
      username: group.name,
      email: '',
      profilePicture: group.picture,
      isTyping: _groupTypingIds.contains(group.id),
      lastMessage: preview,
      timestampLabel: group.lastMessageTimestamp != null
          ? getDateLabel(group.lastMessageTimestamp!)
          : null,
      unreadCount: group.unreadCount,
      onTap: () => _openGroup(group),
    );
  }

  List<Widget> _buildProfileTab() {
    return [
      SliverToBoxAdapter(
        child: FutureBuilder<User>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚠️ Failed to load profile'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _profileFuture = _fetchProfile();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final profile = snapshot.data!;
            return UserProfile(
              profile: profile,
              actions: Row(
                children: [
                  Expanded(
                    child: ProfileActionButton(
                      icon: PhosphorIconsBold.pencilSimpleLine,
                      label: 'Edit Profile',
                      onTap: () => _showEditProfileComingSoon(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileActionButton(
                      icon: PhosphorIconsBold.export,
                      label: 'Share Profile',
                      onTap: () => _shareProfile(profile),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  void _showCallDialog(
    UserWithLastMessage user, {
    required Offset anchorTopLeft,
    required Size anchorSize,
  }) {
    final userBasic = User(
      id: user.id,
      username: user.username,
      profilePicture: user.profilePicture,
    );

    FloatingActionMenu.show(
      context: context,
      anchorTopLeft: anchorTopLeft,
      anchorSize: anchorSize,
      actions: [
        FloatingMenuAction(
          icon: PhosphorIconsBold.phone,
          label: 'Voice Call',
          onTap: () => _startCall(userBasic, callType: 'audio'),
        ),
        FloatingMenuAction(
          icon: PhosphorIconsBold.videoCamera,
          label: 'Video Call',
          onTap: () => _startCall(userBasic, callType: 'video'),
        ),
      ],
    );
  }
}
