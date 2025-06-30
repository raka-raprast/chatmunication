import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/utils/helpers.dart';
import 'package:flutter/material.dart';

class CMAvatar extends StatelessWidget {
  CMAvatar(
      {super.key,
      required this.profilePicture,
      required this.email,
      required this.username,
      this.size = 50});
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
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              CMColors.primary.withValues(alpha: 0.1),
              CMColors.primaryVariant.withValues(alpha: 0.15)
              // email.isNotEmpty
              //     ? colorList[CMHelpers.getStringIndex(email)]
              //     : CMColors.primary.withValues(alpha: 0.1),
              // username.isNotEmpty
              //     ? colorList[CMHelpers.getStringIndex(username)]
              //     : CMColors.primaryVariant.withValues(alpha: 0.15),
            ]),
          ),
        ),
        Center(
          child: Text(
            getFirstLetters(username),
            style: CMTextStyle.title.copyWith(
              fontSize: size * .45,
              color: CMColors.primaryVariant,
            ),
          ),
          // child: Icon(
          //   Icons.person,
          //   color: CMColors.primaryVariant,
          //   size: size * .55,
          // ),
        )
      ],
    );
  }
}
