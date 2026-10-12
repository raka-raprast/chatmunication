import 'dart:convert';

import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/shared/config/app_config.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl;
  final String token;

  UserService({required this.token, String? baseUrl})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }
  }

  Future<List<UserWithLastMessage>> getUsersWithLastMessage() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/with-last-message'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.map((e) => UserWithLastMessage.fromJson(e)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load users with messages');
    }
  }

  /// ✅ Send a friend request by user ID (or auto-accept if they already
  /// sent us one).
  Future<void> addContact(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/contacts/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        _extractError(response.body) ?? 'Failed to send friend request',
      );
    }
  }

  /// ✅ Accept an incoming friend request from [userId].
  Future<void> acceptContact(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/contacts/$userId/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body) ?? 'Failed to accept friend request',
      );
    }
  }

  /// ✅ Decline an incoming friend request from [userId].
  Future<void> declineContact(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/contacts/$userId/decline'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body) ?? 'Failed to decline friend request',
      );
    }
  }

  /// ✅ Incoming friend requests awaiting our decision.
  Future<List<User>> getIncomingContactRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/contacts/requests'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load friend requests');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((json) => User.fromJson(json)).toList();
  }

  /// ✅ Friend requests we sent, still awaiting their decision.
  Future<List<User>> getSentContactRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/contacts/requests/sent'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load sent requests');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((json) => User.fromJson(json)).toList();
  }

  String? _extractError(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map ? data['error'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  /// ✅ Remove contact by user ID
  Future<void> removeContact(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/contacts/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove contact: ${response.statusCode}');
    }
  }

  /// ✅ Search for users to add
  Future<List<User>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to search users: ${response.statusCode}');
    }
  }

  /// ✅ Get a single user by ID, including their contactStatus relative
  /// to the authenticated user.
  Future<User> getUserById(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Failed to fetch user: ${response.statusCode}');
    }
  }

  /// ✅ Mark all messages from [fromUserId] to the current user as read.
  Future<void> markMessagesRead(String fromUserId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/messages/read?from=$fromUserId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark messages read: ${response.statusCode}');
    }
  }

  /// ✅ Register this device's FCM token so the server can push
  /// notifications for messages/calls received while offline.
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/fcm-token'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': fcmToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update FCM token: ${response.statusCode}');
    }
  }
}
