import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

class CMTextField extends StatelessWidget {
  const CMTextField({
    super.key,
    this.controller,
    this.label,
    this.obscureText = false,
    this.decoration,
    this.prefix,
    this.suffix,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.keyboardType = TextInputType.text,
    this.maxLines,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? label;
  final bool obscureText;
  final InputDecoration? decoration;
  final Widget? prefix;
  final Widget? suffix;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: textAlign,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        color: CMColors.text,
        fontSize: 16,
      ),
      decoration: decoration ??
          InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            hintText: label,
            filled: true,
            fillColor: CMColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: CMColors.surface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: CMColors.surface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: CMColors.primary, width: 2),
            ),
            hintStyle: TextStyle(color: CMColors.hint),
            prefixIcon: prefix,
            suffixIcon: suffix,
          ),
      obscureText: obscureText,
    );
  }
}
