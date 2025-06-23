import 'dart:developer';

import 'package:chatmunication/features/auth/service/auth_service.dart';
import 'package:chatmunication/features/call/call_screen.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final roomController = TextEditingController();
  final authService = AuthService();

  bool isLogin = true;
  String? error;
  String role = 'caller'; // Default role

  void _submit() async {
    final username = usernameController.text;
    final password = passwordController.text;
    final roomId = roomController.text;

    String? token;
    if (isLogin) {
      log("login");
      token = await authService.login(username, password);
    } else {
      log("register");
      token = await authService.register(username, password);
    }

    if (token != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            token: token!,
            roomId: roomId,
            isCaller: role == 'caller',
          ),
        ),
      );
    } else {
      setState(() {
        error = 'Auth failed. Check username/password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: roomController,
              decoration: InputDecoration(labelText: 'Room ID'),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'caller', child: Text('Caller')),
                DropdownMenuItem(value: 'callee', child: Text('Callee')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    role = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _submit,
              child: Text(isLogin ? 'Login & Join' : 'Register & Join'),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Create new account' : 'Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
