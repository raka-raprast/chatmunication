import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/utils/helpers.dart';
import 'package:flutter/material.dart';

class CMAvatar extends StatelessWidget {
  CMAvatar({
    super.key,
    required this.profilePicture,
    required this.email,
    required this.username,
    this.size = 50,
  });
  final String profilePicture;
  final String email;
  final String username;
  final double size;
  final List<Color> colorList = [
    const Color.fromARGB(255, 246, 188, 184),
    const Color.fromARGB(255, 251, 221, 175),
    const Color.fromARGB(255, 255, 243, 139),
    const Color.fromARGB(255, 190, 247, 192),
    const Color.fromARGB(255, 165, 250, 241),
    const Color.fromARGB(255, 147, 204, 250),
    const Color.fromARGB(255, 162, 172, 227),
    const Color.fromARGB(255, 225, 150, 238),
    const Color.fromARGB(255, 255, 168, 197),
    const Color.fromARGB(255, 255, 191, 169),
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: profilePicture.isNotEmpty
            ? Image.network(profilePicture)
            : _buildAlphabetName(),
      ),
    );
  }

  String getFirstLetters(String input, {int cap = 3}) {
    return input
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(cap)
        .join();
  }

  Widget _buildAlphabetName() {
    final seed = username.isNotEmpty ? username : email;
    final baseColor = seed.isNotEmpty
        ? colorList[CMHelpers.getStringIndex(seed)]
        : CMColors.primary;
    final hsl = HSLColor.fromColor(baseColor);
    final textColor = hsl
        .withLightness((hsl.lightness - 0.35).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.15).clamp(0.0, 1.0))
        .toColor();
    final bgTop = Color.lerp(Colors.white, baseColor, 0.14)!;
    final bgBottom = Color.lerp(Colors.white, baseColor, 0.32)!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgBottom],
            ),
          ),
        ),
        Center(
          child: Text(
            getFirstLetters(username, cap: 1),
            style: CMTextStyle.title.copyWith(
              fontSize: size * .45,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
