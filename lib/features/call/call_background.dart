import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:flutter/material.dart';

/// Soft pastel-blue gradient + blurred color blobs used behind every
/// audio-call surface (ringing, in-call, incoming) for a consistent feel.
class CallGradientBackground extends StatelessWidget {
  const CallGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Colors.white, CMColors.primary, .08)!,
                  Color.lerp(Colors.white, CMColors.primaryVariant, .18)!,
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _blob(260, CMColors.primary.withValues(alpha: .25)),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _blob(320, CMColors.primaryVariant.withValues(alpha: .20)),
          ),
          Positioned(
            top: 220,
            right: -60,
            child: _blob(180, CMColors.secondary.withValues(alpha: .15)),
          ),
        ],
      ),
    );
  }

  static Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Concentric "ripple" rings behind an avatar — used for both the active
/// audio-call screen and the incoming-call ringing screen.
class RippleAvatar extends StatelessWidget {
  const RippleAvatar({
    super.key,
    required this.username,
    required this.profilePicture,
    this.email = '',
    this.size = 160,
  });

  final String username;
  final String profilePicture;
  final String email;
  final double size;

  @override
  Widget build(BuildContext context) {
    final outer = size * 1.625; // matches the original 160 -> 260 ratio
    final inner = size * 1.3125; // matches the original 160 -> 210 ratio
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: outer,
          height: outer,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CMColors.primary.withValues(alpha: .06),
          ),
        ),
        Container(
          width: inner,
          height: inner,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CMColors.primary.withValues(alpha: .10),
          ),
        ),
        CMAvatar(
          username: username,
          profilePicture: profilePicture,
          email: email,
          size: size,
        ),
      ],
    );
  }
}
