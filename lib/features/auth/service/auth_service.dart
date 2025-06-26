import 'dart:convert';
import 'dart:developer';
import 'package:chatmunication/features/users/user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

      // Extract user data
      final userData = {
        'id': data['user']['id'],
        'username': data['user']['username'],
        'token': data['token'],
        'profile_picture': data['user']['profile_picture'] ?? '',
      };

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(userData));

      return User.fromJson(userData);
    }

    return null;
  }

  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }
}
