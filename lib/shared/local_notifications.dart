import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Foreground heads-up alerts for new chat messages — shown while the app
/// is open but the sender's conversation isn't the one on screen.
/// Background/terminated delivery is handled separately by the server's
/// FCM push (see `signaling.SendChatMessage`'s offline fallback), which
/// the OS displays automatically without going through this plugin.
class LocalNotifications {
  LocalNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _messagesChannel =
      AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'New chat message alerts',
        importance: Importance.high,
      );

  static bool _initialized = false;

  /// Sets up notification channels/permissions. Call once at startup.
  /// [onTap] fires with the sender's user id (stored as the payload) when
  /// the user taps a delivered notification.
  static Future<void> init({void Function(String fromUserId)? onTap}) async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via firebase_messaging
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) onTap?.call(payload);
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_messagesChannel);
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Shows a heads-up notification for an incoming chat message.
  /// [fromUserId] is passed back verbatim as the tap payload.
  static Future<void> showMessage({
    required String fromUserId,
    required String senderName,
    required String content,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      id: fromUserId.hashCode,
      title: senderName,
      body: content,
      payload: fromUserId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _messagesChannel.id,
          _messagesChannel.name,
          channelDescription: _messagesChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
