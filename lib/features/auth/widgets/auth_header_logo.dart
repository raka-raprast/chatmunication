import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

/// "[icon] Chatmunication" wordmark lockup used atop the auth/OTP screens,
/// with "Chat" bold and "munication" in a lighter tint per the design.
class AuthHeaderLogo extends StatelessWidget {
  const AuthHeaderLogo({
    super.key,
    this.iconSize = 56,
    this.fontSize = 30,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final double iconSize;
  final double fontSize;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(iconSize * 0.28),
          child: Image.asset(
            'lib/assets/images/onboarding_app_icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: iconSize * 0.16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Chat',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: CMColors.primaryVariant,
                ),
              ),
              TextSpan(
                text: 'munication',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: CMColors.primary.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
