import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

class NavBarItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const NavBarItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6),
          height: kBottomNavigationBarHeight,
          decoration: BoxDecoration(
            color: isSelected
                ? CMColors.primary.withValues(alpha: .2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? CMColors.background
                : CMColors.primary.withValues(alpha: .4),
          ),
        ),
      ),
    );
  }
}
