import 'dart:developer';

import 'package:chatmunication/features/auth/service/auth_service.dart';
import 'package:chatmunication/features/users/otp_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_list_screen.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sign_in_button/sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();

  final authService = AuthService();

  bool isRememberMe = false;
  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  String? error;

  void _submit() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        (!isLogin && emailController.text.trim().isEmpty)) {
      setState(() => error = 'Please fill all fields');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      User? user;
      if (isLogin) {
        final success = await authService.sendOtp(username, password);
        if (success) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(identifier: username),
            ),
          );
          return;
        } else {
          setState(() => error = 'Failed to send OTP');
        }
      } else {
        user = await authService.register(
            context, username, password, emailController.text.trim());
      }

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserListScreen(
              token: user?.token ?? '',
              userId: user?.id ?? '',
            ),
          ),
        );
      } else {
        setState(() => error = 'Authentication failed.');
      }
    } catch (e) {
      setState(() => error = 'An error occurred: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMScaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'lib/assets/images/logo.png',
                height: 100,
                width: 100,
              ),
              SizedBox(
                height: 24,
              ),
              Text(
                isLogin ? "Welcome!" : "Join us!",
                style: CMTextStyle.title,
              ),
              Text(
                isLogin
                    ? "Communicate with lover, family, friend and co-worker"
                    : "Fill in your detail to communicate with others",
                style: CMTextStyle.text,
              ),
              SizedBox(
                height: 24,
              ),
              if (isLogin) ..._showLogin() else ..._showRegister(),
              if (error != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (!isLogin)
                SizedBox(
                  height: 12,
                ),
              if (isLogin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isRememberMe,
                          onChanged: (v) {
                            setState(() {
                              isRememberMe = !isRememberMe;
                            });
                          },
                          side: BorderSide(
                            color: CMColors.primaryVariant,
                            width: 2,
                          ),
                          activeColor: CMColors.primaryVariant,
                          checkColor: CMColors.surface,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          'Remember me',
                          style: CMTextStyle.text.copyWith(
                            color: CMColors.primaryVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Forgot password',
                      style: CMTextStyle.text.copyWith(
                        color: CMColors.primaryVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CMColors.primaryVariant,
                  disabledBackgroundColor:
                      CMColors.primaryVariant, // <-- Keep color when disabled
                  disabledForegroundColor:
                      Colors.white, // <-- Keep text/spinner color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                ),
                child: isLoading
                    ? const SpinKitFoldingCube(
                        color: CMColors.surface,
                        size: 20.0,
                      )
                    : Text(isLogin ? 'Login' : 'Register',
                        style: CMTextStyle.subtitle.copyWith(
                          color: Colors.white,
                        )),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: CMColors.primaryVariant,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: CMColors.primaryVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: CMColors.primaryVariant,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              SignInButton(
                Buttons.google,
                onPressed: () {},
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              SignInButton(
                Buttons.facebookNew,
                onPressed: () {},
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: isLogin
                        ? "Don't have an account yet? "
                        : "Already have an account? ",
                    style: CMTextStyle.text.copyWith(
                      color: CMColors.text,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(
                        text: isLogin ? 'Create new one' : 'Sign in here',
                        style: CMTextStyle.text.copyWith(
                          color: CMColors.primaryVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => setState(() => isLogin = !isLogin),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _showLogin() {
    return [
      CMTextField(
        controller: usernameController,
        prefix: const Icon(
          Icons.email,
          color: CMColors.primaryVariant,
          size: 24,
        ),
        label: 'Enter your email or username',
      ),
      const SizedBox(height: 16),
      CMTextField(
        controller: passwordController,
        obscureText: !showPassword,
        prefix: const Icon(
          Icons.lock,
          color: CMColors.primaryVariant,
          size: 24,
        ),
        label: 'Enter your password',
        suffix: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            color: CMColors.primaryVariant,
            size: 24,
          ),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
      ),
    ];
  }

  List<Widget> _showRegister() {
    return [
      CMTextField(
        controller: usernameController,
        prefix: const Icon(
          Icons.person,
          color: CMColors.primaryVariant,
          size: 24,
        ),
        label: 'Fill in your username',
      ),
      const SizedBox(height: 12),
      CMTextField(
        controller: fullNameController,
        prefix: const Icon(
          Icons.abc,
          color: CMColors.primaryVariant,
          size: 24,
        ),
        label: 'Fill in your name',
      ),
      const SizedBox(height: 12),
      CMTextField(
        controller: emailController,
        prefix: const Icon(
          Icons.email,
          color: CMColors.primaryVariant,
          size: 24,
        ),
        label: 'Fill in your email address',
      ),
      const SizedBox(height: 12),
      CMTextField(
        controller: passwordController,
        obscureText: !showPassword,
        prefix: const Icon(
          Icons.lock,
          color: CMColors.primaryVariant,
          size: 24,
        ),
        label: 'Enter your password',
        suffix: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            color: CMColors.primaryVariant,
            size: 24,
          ),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
      ),
      const SizedBox(height: 12),
      CMTextField(
        controller: confirmPasswordController,
        obscureText: !showPassword,
        prefix: const Icon(
          Icons.verified_user,
          color: CMColors.primaryVariant,
          size: 24,
        ),
        label: 'Enter your password',
        suffix: IconButton(
          icon: Icon(
            showConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: CMColors.primaryVariant,
            size: 24,
          ),
          onPressed: () =>
              setState(() => showConfirmPassword = !showConfirmPassword),
        ),
      ),
    ];
  }
}
