import 'package:chatmunication/features/onboarding/widgets/onboarding_text.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

/// Page 4 — closing "Bring People Closer" page.
class PageBringPeopleCloser extends StatelessWidget {
  const PageBringPeopleCloser({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Expanded(child: Center(child: _Illustration())),
        const OnboardingHeadline(
          title: 'Bring People\nCloser',
          subtitle: 'Start chatting, calling, and sharing moments with the people who matter in your life.',
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: CMColors.primaryVariant.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'lib/assets/images/onboarding_app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Positioned(
            top: 24,
            left: 20,
            child: _RoundIcon(icon: Icons.videocam_rounded),
          ),
          const Positioned(
            top: 10,
            right: 20,
            child: _RoundIcon(icon: Icons.call_rounded),
          ),
          const Positioned(
            bottom: 26,
            child: _RoundIcon(icon: Icons.chat_bubble_rounded, muted: true),
          ),
          const Positioned(
            top: -14,
            child: _AvatarCircle(
              image: 'lib/assets/images/onboarding_avatar_woman.jpg',
              online: true,
            ),
          ),
          const Positioned(
            left: 4,
            bottom: 30,
            child: _AvatarCircle(
              image: 'lib/assets/images/onboarding_avatar_asian_man.jpg',
              online: true,
            ),
          ),
          const Positioned(
            right: 4,
            bottom: 30,
            child: _AvatarCircle(
              image: 'lib/assets/images/onboarding_avatar_man.jpg',
              online: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.muted = false});
  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: muted
            ? CMColors.primary.withValues(alpha: 0.5)
            : CMColors.primaryVariant,
        size: 22,
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.image, required this.online});
  final String image;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(child: Image.asset(image, fit: BoxFit.cover)),
        ),
        if (online)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34C759),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
