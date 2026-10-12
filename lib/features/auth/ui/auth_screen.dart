import 'dart:ui';

import 'package:chatmunication/features/auth/service/auth_service.dart';
import 'package:chatmunication/features/auth/widgets/auth_background.dart';
import 'package:chatmunication/features/auth/widgets/auth_header_logo.dart';
import 'package:chatmunication/features/auth/widgets/auth_primary_button.dart';
import 'package:chatmunication/features/users/otp_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_list_screen.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  bool isRememberMe = true;
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
              builder: (_) =>
                  OtpScreen(identifier: username, password: password),
            ),
          );
          return;
        } else {
          setState(() => error = 'Failed to send OTP');
        }
      } else {
        user = await authService.register(
          context,
          username,
          password,
          emailController.text.trim(),
        );
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
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            const Positioned.fill(child: AuthBackground(showBubbles: true)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeaderLogo(),
                    const SizedBox(height: 14),
                    Text(
                      isLogin
                          ? 'Communicate with lover,\nfamily, friend and co-worker'
                          : 'Fill in your detail to\ncommunicate with others',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                isLogin ? 'Welcome back!' : 'Create account!',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF12213B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isLogin
                                    ? 'Sign in to continue to Chatmunication'
                                    : 'Sign up to get started with Chatmunication',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (isLogin)
                                ..._showLogin()
                              else
                                ..._showRegister(),
                              if (error != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  error!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (isLogin) ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Checkbox(
                                            value: isRememberMe,
                                            onChanged: (v) {
                                              setState(() {
                                                isRememberMe = !isRememberMe;
                                              });
                                            },
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            activeColor:
                                                CMColors.primaryVariant,
                                            checkColor: Colors.white,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Remember me',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blueGrey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: CMColors.primaryVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 20),
                              AuthPrimaryButton(
                                label: isLogin ? 'Login' : 'Register',
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: SignInButton(
                                    Buttons.google,
                                    text: 'Continue with Google',
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF12213B),
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: isLogin
                                      ? "Don't have an account yet? "
                                      : 'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: isLogin
                                          ? 'Create new one'
                                          : 'Sign in here',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: CMColors.primaryVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () =>
                                            setState(() => isLogin = !isLogin),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool obscureText = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CMTextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        hintText: label,
        hintStyle: TextStyle(color: CMColors.hint, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CMColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: CMColors.primaryVariant, size: 18),
          ),
        ),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: CMColors.primary, width: 1.6),
        ),
      ),
    );
  }

  List<Widget> _showLogin() {
    return [
      _field(
        controller: usernameController,
        icon: Icons.email_rounded,
        label: 'Enter your email or username',
      ),
      const SizedBox(height: 16),
      _field(
        controller: passwordController,
        icon: Icons.lock_rounded,
        obscureText: !showPassword,
        label: 'Enter your password',
        suffix: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: Colors.blueGrey.shade400,
            size: 20,
          ),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
      ),
    ];
  }

  List<Widget> _showRegister() {
    return [
      _field(
        controller: usernameController,
        icon: Icons.person_rounded,
        label: 'Fill in your username',
      ),
      const SizedBox(height: 16),
      _field(
        controller: fullNameController,
        icon: Icons.badge_rounded,
        label: 'Fill in your name',
      ),
      const SizedBox(height: 16),
      _field(
        controller: emailController,
        icon: Icons.email_rounded,
        label: 'Fill in your email address',
      ),
      const SizedBox(height: 16),
      _field(
        controller: passwordController,
        icon: Icons.lock_rounded,
        obscureText: !showPassword,
        label: 'Enter your password',
        suffix: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: Colors.blueGrey.shade400,
            size: 20,
          ),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
      ),
      const SizedBox(height: 16),
      _field(
        controller: confirmPasswordController,
        icon: Icons.verified_user_rounded,
        obscureText: !showPassword,
        label: 'Confirm your password',
        suffix: IconButton(
          icon: Icon(
            showConfirmPassword
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: Colors.blueGrey.shade400,
            size: 20,
          ),
          onPressed: () =>
              setState(() => showConfirmPassword = !showConfirmPassword),
        ),
      ),
    ];
  }
}
