import 'package:chatmunication/features/onboarding/widgets/onboarding_phone_frame.dart';
import 'package:chatmunication/features/onboarding/widgets/onboarding_text.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

/// Page 1 — brand intro: "Stay Connected with Everyone".
class PageStayConnected extends StatelessWidget {
  const PageStayConnected({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('lib/assets/images/logo.png', height: 46),
        const SizedBox(height: 32),
        const OnboardingHeadline(
          title: 'Stay Connected\nwith Everyone',
          subtitle: 'Chat, call, and video call with your family, friends, and colleagues anytime, anywhere.',
        ),
        const SizedBox(height: 36),
        Expanded(child: Center(child: _Illustration())),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 340,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.035,
            child: OnboardingPhoneFrame(
              width: 240,
              height: 320,
              child: _ChatPreview(),
            ),
          ),
          const Positioned(
            top: 6,
            right: 6,
            child: _IconChip(icon: Icons.videocam_rounded),
          ),
          Positioned(
            left: 4,
            top: 90,
            child: _RoundIconButton(icon: Icons.call_rounded),
          ),
          const Positioned(left: 8, bottom: 76, child: _TypingBubble()),
          const Positioned(
            right: 6,
            bottom: 70,
            child: _IconChip(icon: Icons.image_rounded),
          ),
        ],
      ),
    );
  }
}

class _ChatPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          _bar(
            width: 130,
            height: 34,
            color: Colors.grey.shade100,
            alignRight: false,
          ),
          const SizedBox(height: 14),
          _bar(
            width: 160,
            height: 44,
            color: CMColors.primary,
            alignRight: true,
            trailing: '11:24',
          ),
          const SizedBox(height: 14),
          _bar(
            width: 130,
            height: 34,
            color: Colors.grey.shade100,
            alignRight: false,
          ),
        ],
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required Color color,
    required bool alignRight,
    String? trailing,
  }) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width * 0.6,
              height: 6,
              decoration: BoxDecoration(
                color: alignRight
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: CMColors.primaryVariant, size: 24),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [CMColors.primary, CMColors.primaryVariant],
        ),
        boxShadow: [
          BoxShadow(
            color: CMColors.primaryVariant.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: CMColors.primaryVariant,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
