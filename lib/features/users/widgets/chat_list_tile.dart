import 'dart:ui';

import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Rounded chat-list row card: avatar with presence dot, name + timestamp,
/// last message preview with a direction glyph, and either an unread
/// indicator (chat list) or a "tap to view profile" affordance (search
/// results — adding/messaging/calling a found user happens from their
/// profile, not inline from the row).
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.username,
    required this.email,
    required this.profilePicture,
    required this.onTap,
    this.onLongPress,
    this.isOnline = false,
    this.isTyping = false,
    this.lastMessage,
    this.timestampLabel,
    this.unreadCount = 0,
    this.isSearchResult = false,
  });

  final String username;
  final String email;
  final String profilePicture;
  final VoidCallback onTap;
  final void Function(Offset topLeft, Size size)? onLongPress;
  final bool isOnline;
  final bool isTyping;
  final String? lastMessage;
  final String? timestampLabel;
  final int unreadCount;
  final bool isSearchResult;

  @override
  Widget build(BuildContext context) {
    final hasUnread = !isSearchResult && unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CMColors.primaryVariant.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                onLongPress: onLongPress == null
                    ? null
                    : () {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null || !box.hasSize) return;
                        onLongPress!(box.localToGlobal(Offset.zero), box.size);
                      },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          CMAvatar(
                            profilePicture: profilePicture,
                            email: email,
                            username: username,
                            size: 40,
                          ),
                          if (!isSearchResult)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    username,
                                    style: CMTextStyle.subtitle.copyWith(
                                      color: CMColors.text,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isSearchResult && timestampLabel != null)
                                  Text(
                                    timestampLabel!,
                                    style: CMTextStyle.small.copyWith(
                                      color: CMColors.hint,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: isSearchResult
                                      ? Text(
                                          email,
                                          style: CMTextStyle.small.copyWith(
                                            color: CMColors.hint,
                                            fontSize: 11,
                                          ),
                                        )
                                      : isTyping
                                      ? Text(
                                          'typing...',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                            color: CMColors.primaryVariant,
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              PhosphorIconsBold.caretDoubleLeft,
                                              size: 11,
                                              color: CMColors.hint,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                lastMessage ??
                                                    'No messages yet',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: hasUnread
                                                      ? CMColors.text
                                                      : CMColors.hint,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                if (isSearchResult)
                                  Icon(
                                    PhosphorIconsBold.caretRight,
                                    color: CMColors.hint,
                                    size: 16,
                                  )
                                else if (hasUnread)
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                    ),
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: CMColors.primaryVariant,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(999),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
