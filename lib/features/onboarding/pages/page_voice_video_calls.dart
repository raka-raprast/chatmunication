import 'package:chatmunication/features/onboarding/widgets/onboarding_phone_frame.dart';
import 'package:chatmunication/features/onboarding/widgets/onboarding_text.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

/// Page 3 — "Crystal Clear Voice & Video Calls" mockup.
class PageVoiceVideoCalls extends StatelessWidget {
  const PageVoiceVideoCalls({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const OnboardingHeadline(
          title: 'Crystal Clear\nVoice & Video Calls',
          subtitle: 'Make high quality voice and video calls with the people who matter.',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: OnboardingPhoneFrame(
              width: 240,
              height: 440,
              padding: const EdgeInsets.all(0),
              child: const _CallMockup(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CallMockup extends StatelessWidget {
  const _CallMockup();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'lib/assets/images/onboarding_call_main.png',
          fit: BoxFit.cover,
        ),
        Positioned(
          top: 12,
          left: 12,
          child: _glassIcon(Icons.flip_camera_ios_outlined),
        ),
        Positioned(top: 12, right: 12, child: _glassIcon(Icons.more_horiz)),
        Positioned(
          right: 14,
          bottom: 90,
          child: Container(
            width: 76,
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'lib/assets/images/onboarding_call_pip.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  Icons.volume_up_rounded,
                  Colors.white,
                  CMColors.primaryVariant,
                ),
                _controlButton(
                  Icons.mic_rounded,
                  Colors.white,
                  CMColors.primaryVariant,
                ),
                _controlButton(
                  Icons.videocam_rounded,
                  Colors.white,
                  CMColors.primaryVariant,
                ),
                _controlButton(
                  Icons.call_end_rounded,
                  Colors.red,
                  Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassIcon(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.25),
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }

  Widget _controlButton(IconData icon, Color bg, Color fg) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Icon(icon, color: fg, size: 19),
    );
  }
}
