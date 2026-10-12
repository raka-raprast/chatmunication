import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

class CMFloatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool isTransparent;

  const CMFloatingAppBar({
    super.key,
    this.height = kToolbarHeight,
    this.title,
    this.leading,
    this.actions,
    this.isTransparent = false,
  });
  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background + Shadow Layer
        if (!isTransparent)
          Positioned(
            left: 12,
            right: 12,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .15),
                    blurRadius: 5,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),

        // Foreground Layer
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isTransparent
                ? null
                : LinearGradient(
                    colors: [
                      CMColors.primary.withValues(alpha: .1),
                      CMColors.primaryVariant.withValues(alpha: .15),
                    ],
                  ),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              if (leading != null) leading!,
              if (title != null)
                Expanded(
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    child: title!,
                  ),
                )
              else
                const Spacer(), // push actions to the right even if title is null
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
