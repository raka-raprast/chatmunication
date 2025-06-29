import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

class CMBackButton extends StatelessWidget {
  const CMBackButton({super.key, this.onBack});
  final Function()? onBack;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: CMColors.primaryVariant,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: CMColors.surface,
          )),
      onPressed: onBack ?? () => Navigator.pop(context),
    );
  }
}
