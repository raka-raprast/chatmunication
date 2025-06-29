import 'dart:convert';
import 'dart:developer';

import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/incoming_call_screen.dart';
import 'package:chatmunication/features/users/message_screen.dart';
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
    userSocket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CMScaffold(
      useGradientBackground: false,
      floatingAppBar: CMFloatingAppBar.search(),
      body: CustomScrollView(
        slivers: _selectedIndex == 0 ? _buildChatList() : _buildProfileTab(),
      ),
      // body: _selectedIndex == 0 ? _buildChatList() : _buildProfileTab(),
      bottomNavigationBar: _buildNavBar(),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: (index) => setState(() => _selectedIndex = index),
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.chat),
      //       label: 'Chat',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person),
      //       label: 'Profile',
      //     ),
      //   ],
      // ),
    );
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
      FutureBuilder<List<UserWithLastMessage>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
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

          log(inspect(users).toString());

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = users[index];
                return Container(
                  // margin: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CMColors.text, width: .5),
                    ),
                  ),
                  child: ListTile(
                    onTap: () => _startChat(User(
                      id: user.id,
                      username: user.username,
                      profilePicture: user.profilePicture,
                      email: user.email,
                    )),
                    onLongPress: () => _showCallDialog(user),
                    leading: Stack(
                      children: [
                        CMAvatar(
                          profilePicture: user.profilePicture,
                          email: user.email ?? '',
                          username: user.username,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _onlineStatus[user.id] == true
                                  ? Colors.green
                                  : Colors.grey,
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
                          user.username,
                          style: CMTextStyle.subtitle
                              .copyWith(color: CMColors.text),
                        ),
                        Text(
                          getDateLabel(
                            user.lastMessageTimestamp ?? DateTime.now(),
                          ),
                          style: CMTextStyle.small,
                        )
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        if (!(user.isSender ?? false))
                          Icon(
                            Icons.reply,
                            size: 12,
                            color: CMColors.text,
                          ),
                        Text(
                          user.lastMessageContent ?? "No messages yet",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: users.length,
            ),
          );
        },
      )
    ];
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profile.profilePicture.isNotEmpty
                        ? NetworkImage(profile.profilePicture)
                        : null,
                    child: profile.profilePicture.isEmpty
                        ? Text(
                            profile.username[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.username,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${profile.id}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: ${profile.email}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
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
