import 'package:chatmunication/features/onboarding/widgets/onboarding_phone_frame.dart';
import 'package:chatmunication/features/onboarding/widgets/onboarding_text.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

/// Page 2 — "Real-time Messaging" chat mockup.
class PageRealtimeMessaging extends StatelessWidget {
  const PageRealtimeMessaging({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const OnboardingHeadline(
          title: 'Real-time\nMessaging',
          subtitle: 'Send text, photos, videos, and files instantly. Keep your conversations smooth and organized.',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: OnboardingPhoneFrame(
              width: 300,
              height: 420,
              padding: const EdgeInsets.all(0),
              child: const _ChatMockup(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMockup extends StatelessWidget {
  const _ChatMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(),
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReceivedBubble(),
                const SizedBox(height: 10),
                _SentBubble(),
                const SizedBox(height: 10),
                _PhotoRow(),
                const SizedBox(height: 10),
                _VoiceMessage(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Icon(Icons.chevron_left, color: CMColors.primaryVariant, size: 22),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CMColors.primary.withValues(alpha: 0.15),
            ),
            child: Text(
              'J',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: CMColors.primaryVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'John Doe',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          _headerIcon(Icons.videocam_rounded),
          const SizedBox(width: 6),
          _headerIcon(Icons.call_rounded),
          const SizedBox(width: 6),
          _headerIcon(Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
      ),
      child: Icon(icon, size: 13, color: CMColors.primaryVariant),
    );
  }
}

class _ReceivedBubble extends StatelessWidget {
  const _ReceivedBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: const Text(
          'Hi! 👋\nHow are you today?',
          style: TextStyle(fontSize: 11.5, height: 1.35),
        ),
      ),
    );
  }
}

class _SentBubble extends StatelessWidget {
  const _SentBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 210),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CMColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
        ),
        child: const Text(
          "I'm good! Here are the photos from our trip.",
          style: TextStyle(fontSize: 11.5, height: 1.35, color: Colors.white),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow();

  static const _photos = [
    'lib/assets/images/onboarding_photo_lake.jpg',
    'lib/assets/images/onboarding_photo_villa.jpg',
    'lib/assets/images/onboarding_photo_temple.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final isLast = i == 2;
          return Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Image.asset(_photos[i], fit: BoxFit.cover),
                if (isLast)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    alignment: Alignment.center,
                    child: const Text(
                      '+3',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _VoiceMessage extends StatelessWidget {
  const _VoiceMessage();

  static const _bars = [
    6.0,
    12.0,
    8.0,
    16.0,
    10.0,
    14.0,
    7.0,
    12.0,
    9.0,
    15.0,
    6.0,
    11.0,
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CMColors.primaryVariant,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _bars
                  .map(
                    (h) => Container(
                      width: 2,
                      height: h,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: CMColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 6),
            Text(
              '0:24',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
