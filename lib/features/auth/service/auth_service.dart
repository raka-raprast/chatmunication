import 'dart:convert';
import 'dart:developer';
import 'package:chatmunication/features/users/otp_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://192.168.100.113:2340/auth';

  Future<User?> register(BuildContext context, String username, String password,
      String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'profile_picture': '',
      }),
    );

    if (res.statusCode == 200) {
      bool otpSent = await sendOtp(username, password);
      return otpSent
          ? Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(identifier: username),
              ),
            )
          : null;
    }

    return null;
  }

  /// Step 1: Send login request and receive OTP (no JWT returned yet)
  Future<bool> sendOtp(String identifier, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );

    return res.statusCode == 200;
  }

  /// Step 2: Verify OTP to complete login and receive JWT + user info
  Future<User?> verifyOtp(String identifier, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'otp': otp,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final userData = {
        'id': data['user']['id'],
        'username': data['user']['username'],
        'token': data['token'],
        'email': data['user']['email'] ?? '',
        'profile_picture': data['user']['profile_picture'] ?? '',
      };

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
