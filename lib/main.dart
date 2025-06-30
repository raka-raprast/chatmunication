import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/users/incoming_call_screen.dart';
import 'package:chatmunication/firebase_options.dart';
import 'package:chatmunication/shared/startup_screen.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:callkeep/callkeep.dart';
import 'package:uuid/uuid.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

    // 🔐 Get the FCM token
    String? fcmToken = await messaging.getToken();
    print("📱 FCM Token: $fcmToken");

    // TODO: send this token to your server for future calls
  } else {
    print('❌ FCM permission declined');
  }

  // 🎯 Handle foreground messages
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
    }
  });

  // 🔁 Handle when app is opened from background or terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🚪 App opened via notification');
    // TODO: Navigate to call screen
  });
}
