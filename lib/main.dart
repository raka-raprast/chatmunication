import 'dart:convert';

import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/users/incoming_call_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_list_screen.dart';
import 'package:chatmunication/firebase_options.dart';
import 'package:chatmunication/shared/in_app_notification.dart';
import 'package:chatmunication/shared/local_notifications.dart';
import 'package:chatmunication/shared/navigation.dart';
import 'package:chatmunication/shared/startup_screen.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:callkeep/callkeep.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final callKeep = FlutterCallkeep();
final Map<String, Map<String, dynamic>> _callDataMap = {};

Future<void> setupCallKeep() async {
  await callKeep.setup(
    showAlertDialog: () async {
      final ctx = navigatorKey.currentContext!;
      return await showDialog<bool>(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Permissions Required'),
              content: const Text('This app needs call permissions'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('OK')),
              ],
            ),
          ) ??
          false;
    },
    options: <String, dynamic>{
      'ios': {'appName': 'Chatmunication'},
      'android': {
        'additionalPermissions': [
          'android.permission.CALL_PHONE',
          'android.permission.READ_PHONE_NUMBERS'
        ],
        'foregroundService': {
          'channelId': 'com.example.app',
          'channelName': 'Call Service',
          'notificationTitle': 'App is active',
          'notificationIcon': 'mipmap/ic_launcher',
        },
      },
    },
  );

  callKeep.on<CallKeepPerformAnswerCallAction>(_onAnswerCall);
  callKeep.on<CallKeepPerformEndCallAction>(_onEndCall);
}

void _onAnswerCall(CallKeepPerformAnswerCallAction event) {
  final extras = event.callData.additionalData; // This is `additionalData`

  final callerId = extras != null ? extras['callerId'] : null;
  final roomId = extras != null ? extras['roomId'] : null;
  final username = extras != null ? extras['username'] : null;
  final profilePicture = extras != null ? extras['profilePicture'] : null;
  final callType = extras != null ? extras['callType'] : null;
  final token = extras != null ? extras['token'] ?? '' : '';

  navigatorKey.currentState?.push(MaterialPageRoute(
    builder: (_) => IncomingCallScreen(
      callerId: callerId,
      roomId: roomId,
      token: token,
      fromName: username,
      profilePicture: profilePicture,
      callType: callType,
      userSocket: UserSocketService.instance,
    ),
  ));

  callKeep.setCurrentCallActive(event.callData.callUUID ?? '');
}

void _onEndCall(CallKeepPerformEndCallAction event) {
  print("📴 Call ended: ${event.callUUID}");
  _callDataMap.remove(event.callUUID); // cleanup

  // Optional: navigate back or show a toast if needed
}

/// Navigates to the chat list using the persisted session, if any — used
/// when the user taps a message notification (foreground local alert, or
/// a background/terminated FCM push) rather than opening the app cold.
Future<void> _navigateToChatList() async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('user');
  if (userJson == null) return;

  final user = User.fromJson(jsonDecode(userJson));
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) =>
          UserListScreen(token: user.token ?? '', userId: user.id),
    ),
    (route) => false,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalNotifications.init(
    onTap: (fromUserId) => _navigateToChatList(),
  );
  await setupFCM();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatmunication',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const StartupScreen(),
    );
  }
}

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🔑 Request permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ FCM permission granted');
  } else {
    print('❌ FCM permission declined');
  }

  // 🎯 Handle foreground messages. Background/terminated delivery is
  // handled by the OS automatically (the server sends a `notification`
  // payload), so this only covers the app-is-open case.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final data = message.data;

    if (data['type'] == 'incoming_call') {
      final callUUID = const Uuid().v4();

      await callKeep.displayIncomingCall(
        uuid: callUUID,
        handle: data['from'],
        callerName: data['username'] ?? '',
        hasVideo: data['call_type'] == 'video',
        additionalData: {
          'callerId': data['from'],
          'roomId': data['room'],
          'username': data['username'],
          'profilePicture': data['profile_picture'] ?? '',
          'callType': data['call_type'] ?? 'video',
          'token': '', // add token if needed
        },
      );
    } else if (data['type'] == 'chat_message') {
      // Only reaches the client via FCM when the server already decided
      // the recipient's socket wasn't connected (see
      // signaling.SendChatMessage) — e.g. a brief reconnect gap while the
      // app is still foregrounded. Show the same in-app banner the
      // socket path would have triggered.
      final fromUserId = data['from'];
      if (fromUserId == null) return;
      InAppNotificationBanner.show(
        title: message.notification?.title ?? 'New message',
        message: message.notification?.body ?? '',
        profilePicture: '',
        onTap: _navigateToChatList,
      );
    }
  });

  // 🔁 Handle when the app is opened by tapping a background/terminated
  // notification.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      _navigateToChatList();
    }
  });
}
