import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

/// A frosted-glass phone silhouette used to frame the small in-app
/// mockups shown on the onboarding illustrations.
class OnboardingPhoneFrame extends StatelessWidget {
  const OnboardingPhoneFrame({
    super.key,
    required this.child,
    this.width = 280,
    this.height = 400,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final double width;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CMColors.primary.withValues(alpha: 0.20),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(color: Colors.white, child: child),
      ),
    );
  }
}
