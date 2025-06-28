import 'dart:convert';

import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_list_screen.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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

    // Simulate a splash screen delay (e.g., loading animation)
    await Future.delayed(const Duration(seconds: 5));

    final userJson = prefs.getString('user');

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
    return CMScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'lib/assets/images/logo.png',
            height: 370,
            width: 370,
          ),
          SpinKitFoldingCube(
            color: CMColors.primaryVariant,
          ),
        ],
      ),
    );
  }
}
