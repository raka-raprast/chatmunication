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
        return []; // Return empty list if body is not a List
      }
    } else {
      throw Exception('Failed to load users with messages');
    }
  }
}
