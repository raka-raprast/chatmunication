import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:flutter/material.dart';

class CMFloatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final bool isSearch;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;

  const CMFloatingAppBar({
    super.key,
    this.height = kToolbarHeight,
    this.title,
    this.leading,
    this.actions,
  }) : isSearch = false;

  const CMFloatingAppBar.search({
    super.key,
    this.height = kToolbarHeight,
  })  : isSearch = true,
        title = null,
        leading = null,
        actions = null;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background + Shadow Layer
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
                  color: Colors.black.withOpacity(0.15),
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
            gradient: LinearGradient(colors: [
              CMColors.primary.withOpacity(0.1),
              CMColors.primaryVariant.withOpacity(0.15),
            ]),
          ),
          alignment: Alignment.centerLeft,
          child: isSearch
              ? const SizedBox(
                  height: 35,
                  child: CMTextField(
                    isSmall: true,
                    radius: 999,
                    label: 'Search by username or email',
                    prefix: Icon(
                      Icons.search,
                      color: CMColors.primaryVariant,
                      size: 24,
                    ),
                  ),
                )
              : Row(
                  children: [
                    if (leading != null) leading!,
                    if (title != null)
                      Expanded(
                        child: DefaultTextStyle(
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
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
                            .map((action) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: action,
                                ))
                            .toList(),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
