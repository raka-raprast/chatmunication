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
    const Color.fromARGB(255, 238, 152, 146),
    const Color.fromARGB(255, 255, 192, 97),
    const Color.fromARGB(255, 255, 243, 139),
    const Color.fromARGB(255, 163, 250, 166),
    const Color.fromARGB(255, 165, 250, 241),
    Colors.blue,
    const Color.fromARGB(255, 124, 139, 223),
    const Color.fromARGB(255, 225, 150, 238),
    const Color.fromARGB(255, 224, 126, 159),
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

  Widget _buildAlphabetName() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              email.isNotEmpty
                  ? colorList[CMHelpers.getStringIndex(email)]
                  : CMColors.primary.withValues(alpha: 0.1),
              username.isNotEmpty
                  ? colorList[CMHelpers.getStringIndex(username)]
                  : CMColors.primaryVariant.withValues(alpha: 0.15),
            ]),
          ),
        ),
        Center(
          child: Icon(
            Icons.person,
            color: CMColors.background,
            size: 28,
          ),
        )
      ],
    );
  }
}
