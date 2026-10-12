import 'package:chatmunication/features/auth/widgets/auth_header_logo.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Chat list filter tabs. [all], [unread], and [groups] are all backed by
/// real data; [favorites] still renders an honest empty state because the
/// backend has no favorite-contact concept yet.
enum ChatFilter { all, unread, groups, favorites }

/// Composite floating header for the chat list: brand wordmark + a
/// notification bell, the search field with a filter-options button, and
/// the filter chip row (All / Unread / Groups / Favorites).
class ChatListHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatListHeader({
    super.key,
    required this.onSearchTap,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.hasUnread,
    required this.pendingRequestsCount,
    required this.onBellTap,
    this.onFilterTap,
  });

  final VoidCallback onSearchTap;
  final ChatFilter selectedFilter;
  final ValueChanged<ChatFilter> onFilterChanged;
  final bool hasUnread;
  final int pendingRequestsCount;
  final VoidCallback onBellTap;
  final VoidCallback? onFilterTap;

  static const double _height = 190;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const AuthHeaderLogo(iconSize: 36, fontSize: 20),
              const Spacer(),
              _NotificationBell(count: pendingRequestsCount, onTap: onBellTap),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: CMTextField(
                    readOnly: true,
                    onTap: onSearchTap,
                    radius: 999,
                    label: 'Search by username or email',
                    prefix: const Icon(
                      PhosphorIconsBold.magnifyingGlass,
                      color: CMColors.primaryVariant,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FilterOptionsButton(onTap: onFilterTap),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: selectedFilter == ChatFilter.all,
                  onTap: () => onFilterChanged(ChatFilter.all),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Unread',
                  selected: selectedFilter == ChatFilter.unread,
                  onTap: () => onFilterChanged(ChatFilter.unread),
                  trailingDot: hasUnread,
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Groups',
                  selected: selectedFilter == ChatFilter.groups,
                  onTap: () => onFilterChanged(ChatFilter.groups),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Favorites',
                  selected: selectedFilter == ChatFilter.favorites,
                  onTap: () => onFilterChanged(ChatFilter.favorites),
                  leadingIcon: PhosphorIconsRegular.star,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.bell,
              color: CMColors.hint,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: CMColors.primaryVariant,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterOptionsButton extends StatelessWidget {
  const _FilterOptionsButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          PhosphorIconsRegular.slidersHorizontal,
          color: CMColors.hint,
          size: 20,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingDot = false,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool trailingDot;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : CMColors.text;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? CMColors.primaryVariant : Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            if (trailingDot) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: CMColors.primaryVariant,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
