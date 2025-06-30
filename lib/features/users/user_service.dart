import 'dart:convert';
import 'package:chatmunication/features/users/user.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl;
  final String token;

  UserService({
    required this.token,
    this.baseUrl = 'http://192.168.100.113:2340/api',
  });

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

  /// ✅ Add contact by user ID
  Future<void> addContact(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/contacts/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add contact: ${response.statusCode}');
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

  /// ✅ Get a single user by ID with isAdded and addedYou status
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
}
