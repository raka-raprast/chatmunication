import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/shared/startup_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatmunication',
      debugShowCheckedModeBanner: false,
      home: const StartupScreen(),
    );
  }
}
