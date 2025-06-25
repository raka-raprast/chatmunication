import 'dart:convert';
import 'dart:developer';
import 'package:chatmunication/features/users/user.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      'http://192.168.100.113:2340/auth'; // Change for production

  Future<User?> register(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'profile_picture': '', // Optional
      }),
    );

    if (res.statusCode == 200) {
      return login(username, password); // Login right after register
    }

    return null;
  }

  Future<User?> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return User.fromJson({
        'id': data['user']['id'],
        'username': data['user']['username'],
        'token': data['token'],
        'profile_picture': data['user']['profile_picture'] ?? '',
      });
    }

    return null;
  }
}
