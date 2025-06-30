import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/incoming_call_screen.dart';
import 'package:chatmunication/features/users/message_screen.dart';
import 'package:chatmunication/features/users/profile_widget.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/nav_bar_item.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserListScreen extends StatefulWidget {
  final String token;
  final String userId;

  const UserListScreen({required this.token, required this.userId});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late UserSocketService userSocket;
  late Future<List<UserWithLastMessage>> _future;
  late Future<User> _profileFuture;
  bool isVideoCall = true;
  bool _isInCallScreen = false;
  final Map<String, bool> onlineUsers = {};
  final Map<String, bool> _onlineStatus = {};
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = UserService(token: widget.token).getUsersWithLastMessage();
    _profileFuture = _fetchProfile();

    userSocket = UserSocketService(
      serverUrl: '192.168.100.113:2340',
      token: widget.token,
      userId: widget.userId,
      onIncomingCall: _onIncomingCall,
      onCallAccepted: _onCallAccepted,
      onCallRejected: _onCallRejected,
      onMessage: (from, content, timestamp) {
        setState(() {
          _future = UserService(token: widget.token).getUsersWithLastMessage();
        });
      },
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
    )..connect();

    userSocket.onMessage = (from, content, timestamp) {
      // If message is sent/received, refresh user list
      setState(() {
        _future = UserService(token: widget.token).getUsersWithLastMessage();
      });
    };
  }

  void _onIncomingCall(String fromUserId, String roomId, String fromName,
      String profilePicture, String callType) {
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

  Future<User> _fetchProfile() async {
    final response = await http.get(
      Uri.parse('http://192.168.100.113:2340/auth/me'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
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

  List<User> _searchResults = [];
  bool _isLoadingSearch = false;
  String? _searchError;

  Future<void> fetchSearchResults(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _searchError = null;
    });

    try {
      // Simulate a 2-second delay
      await Future.delayed(const Duration(seconds: 2));

      final results = await UserService(token: widget.token).searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingSearch = false;
      });
    }
  }

  void _startChat(User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          currentUserId: widget.userId,
          otherUser: user,
          userSocket: userSocket,
        ),
      ),
    );

    // Refresh user list after returning from chat
    setState(() {
      _future = UserService(token: widget.token).getUsersWithLastMessage();
    });
  }

  void _visitProfile(User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          token: widget.token,
          profileId: user.id,
        ),
      ),
    );

    // Refresh user list after returning from chat
    setState(() {
      _future = UserService(token: widget.token).getUsersWithLastMessage();
    });
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
    _debounce?.cancel();
    userSocket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CMScaffold(
      useGradientBackground: false,
      floatingAppBar: _selectedIndex == 0
          ? CMFloatingAppBar.search(
              key: ValueKey('search'),
              controller: searchController,
              onChanged: (query) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                setState(() {
                  _isLoadingSearch = true;
                });
                _debounce = Timer(const Duration(milliseconds: 500), () async {
                  try {
                    await fetchSearchResults(query);
                  } catch (e) {
                    setState(() {
                      _searchError = e.toString();
                    });
                  } finally {
                    setState(() {
                      _isLoadingSearch = false;
                    });
                  }
                });
              },
            )
          : CMFloatingAppBar(
              key: ValueKey('general'),
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(
                  Icons.logout,
                  color: Colors.transparent,
                ),
              ),
              title: Center(
                  child: Text(
                'Profile',
                style: CMTextStyle.subtitle.copyWith(color: CMColors.text),
              )),
              actions: [
                GestureDetector(
                  onTap: _logout,
                  child: CircleAvatar(
                    backgroundColor: CMColors.primaryVariant,
                    child: Icon(
                      Icons.logout,
                      color: CMColors.background,
                    ),
                  ),
                )
              ],
            ),
      body: CustomScrollView(
        slivers: _selectedIndex == 0 ? _buildChatList() : _buildProfileTab(),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Future<void> _addUser(String userId) async {
    try {
      await UserService(token: widget.token).addContact(userId);

      setState(() {
        _searchResults.removeWhere((user) => user.id == userId);
      });

      // Optional: refresh the chat list
      _future = UserService(token: widget.token).getUsersWithLastMessage();
    } catch (e) {
      // Handle error — show a snackbar or dialog if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add user: $e")),
      );
    }
  }

  Widget _buildNavBar() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(colors: [
            CMColors.primary.withValues(alpha: .1),
            CMColors.primaryVariant.withValues(alpha: .15),
          ]),
        ),
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            NavBarItem(
              icon: CupertinoIcons.chat_bubble_fill,
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            NavBarItem(
              icon: CupertinoIcons.person_fill,
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
          ],
        ),
      );

  List<Widget> _buildChatList() {
    return [
      if (searchController.text.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Search Results",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (_isLoadingSearch)
          const SliverToBoxAdapter(
            child: Center(
              child: SpinKitWave(
                color: CMColors.primaryVariant,
                size: 30,
              ),
            ),
          )
        else if (_searchResults.isEmpty && !_isLoadingSearch)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "No results found",
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildUserItem(
                user: _searchResults[index],
                isSearchResult: true,
              ),
              childCount: _searchResults.length,
            ),
          ),
      ],
      FutureBuilder<List<UserWithLastMessage>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Center(
                child: SpinKitFoldingCube(
                  color: CMColors.surface,
                  size: 40.0,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Center(child: Text('⚠️ ${snapshot.error}')),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(child: Text("No users found")),
            );
          }

          final users = snapshot.data!;

          return SliverList(
            delegate: SliverChildListDelegate([
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text("Chats",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...users.map((u) => _buildUserItem(user: u)),
            ]),
          );
        },
      ),
    ];
  }

  Widget _buildUserItem({
    required dynamic user,
    bool isSearchResult = false,
  }) {
    final id = user.id;
    final username = user.username;
    final email = user.email ?? '';
    final profilePicture = user.profilePicture;

    final lastMessage =
        (user is UserWithLastMessage) ? user.lastMessageContent : null;
    final lastTimestamp =
        (user is UserWithLastMessage) ? user.lastMessageTimestamp : null;
    final isSender =
        (user is UserWithLastMessage) ? user.isSender ?? false : false;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CMColors.text, width: .5),
        ),
      ),
      child: ListTile(
        onTap: () => isSearchResult
            ? _visitProfile(user)
            : _startChat(User(
                id: id,
                username: username,
                profilePicture: profilePicture,
                email: email,
              )),
        onLongPress: isSearchResult ? null : () => _showCallDialog(user),
        leading: Stack(
          children: [
            CMAvatar(
              profilePicture: profilePicture,
              email: email,
              username: username,
            ),
            if (!isSearchResult)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color:
                        _onlineStatus[id] == true ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              username,
              style: CMTextStyle.subtitle.copyWith(color: CMColors.text),
            ),
            if (!isSearchResult && lastTimestamp != null)
              Text(
                getDateLabel(lastTimestamp),
                style: CMTextStyle.small,
              ),
          ],
        ),
        subtitle: isSearchResult
            ? Text(email)
            : Row(
                children: [
                  if (!isSender)
                    Icon(Icons.reply, size: 12, color: CMColors.text),
                  Text(
                    lastMessage ?? "No messages yet",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
        trailing: isSearchResult
            ? IconButton(
                icon: Icon(
                  Icons.person_add,
                  color: CMColors.primaryVariant,
                ),
                // onPressed: () {},
                onPressed: () => _addUser(id),
              )
            : null,
      ),
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
            return UserProfile(profile: profile);
          },
        ),
      ),
    ];
  }

  void _showCallDialog(UserWithLastMessage user) {
    showDialog(
      context: context,
      builder: (context) {
        final userBasic = User(
          id: user.id,
          username: user.username,
          profilePicture: user.profilePicture,
        );

        return SimpleDialog(
          title: const Text('Choose Call Type'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _startCall(userBasic, callType: 'audio');
              },
              child: Row(
                children: const [
                  Icon(Icons.call),
                  SizedBox(width: 10),
                  Text('Voice Call'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _startCall(userBasic, callType: 'video');
              },
              child: Row(
                children: const [
                  Icon(Icons.videocam),
                  SizedBox(width: 10),
                  Text('Video Call'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
