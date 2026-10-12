import 'package:flutter/material.dart';

/// Title/subtitle text block shared across onboarding pages.
class OnboardingHeadline extends StatelessWidget {
  const OnboardingHeadline({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Color(0xFF12213B),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: Colors.blueGrey.shade400,
          ),
        ),
      ],
    );
  }
}
