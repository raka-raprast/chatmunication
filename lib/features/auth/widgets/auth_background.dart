import 'package:chatmunication/features/onboarding/widgets/onboarding_background.dart';
import 'package:flutter/material.dart';

/// Decorative backdrop for the auth flow (login/register + OTP).
///
/// The login/register screen uses the exact designed artwork
/// (`auth_login_background.jpg`, with its chat-bubble illustrations and
/// accent curve baked in); the OTP screen reuses the plain onboarding
/// blob-gradient background, matching each screen's design reference.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, this.showBubbles = false});

  final bool showBubbles;

  @override
  Widget build(BuildContext context) {
    if (showBubbles) {
      return Image.asset(
        'lib/assets/images/auth_login_background.jpg',
        fit: BoxFit.cover,
      );
    }
    return const OnboardingBackground();
  }
}
