import 'package:flutter/material.dart';

/// Soft, blurred "cloud" backdrop shared by every onboarding page.
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/assets/images/onboarding_background.jpg',
      fit: BoxFit.cover,
    );
  }
}
