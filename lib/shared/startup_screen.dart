import 'dart:convert';

import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    await Future.delayed(const Duration(seconds: 1)); // simulate splash delay

    if (!mounted) return;

    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserListScreen(
            token: user.token ?? '',
            userId: user.id,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
