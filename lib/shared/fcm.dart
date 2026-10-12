import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Fetches the FCM token, first waiting for the APNS token to be
/// registered on iOS/macOS. Calling `getToken()` before APNS is ready
/// throws `firebase_messaging/apns-token-not-set`.
Future<String?> getFcmToken() async {
  final messaging = FirebaseMessaging.instance;

  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
    String? apnsToken = await messaging.getAPNSToken();
    var retries = 0;
    while (apnsToken == null && retries < 10) {
      await Future.delayed(const Duration(seconds: 1));
      apnsToken = await messaging.getAPNSToken();
      retries++;
    }
    if (apnsToken == null) {
      print('❌ APNS token not available after waiting; skipping FCM token fetch');
      return null;
    }
  }

  try {
    return await messaging.getToken();
  } catch (e) {
    print('⚠️ Failed to get FCM token: $e');
    return null;
  }
}
