import 'dart:ui';

import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/message_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Glass identity card: copyable user ID, avatar, handle/name/email, and an
/// optional [actions] row supplied by the caller (e.g. Edit/Share on the
/// signed-in user's own profile — viewing someone else's profile omits it).
class UserProfile extends StatelessWidget {
  final User profile;
  final Widget? actions;

  const UserProfile({super.key, required this.profile, this.actions});

  /// Derives a lowercase handle from the username for display only — the
  /// backend has no separate handle field, so this is purely a cosmetic
  /// slug of the real username, not a fabricated identifier.
  String get _handle {
    final slug = profile.username.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    return slug.isNotEmpty ? slug : profile.id.substring(0, 6);
  }

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: profile.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CMColors.primaryVariant.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: CMColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'User ID',
                              style: TextStyle(
                                color: CMColors.hint,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                profile.id,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: CMColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _copyId(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          PhosphorIconsRegular.copy,
                          color: CMColors.text,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                CMAvatar(
                  size: 140,
                  profilePicture: profile.profilePicture,
                  email: profile.email ?? '',
                  username: profile.username,
                ),
                const SizedBox(height: 18),
                Text(
                  '@$_handle',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: CMColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: CMColors.text,
                  ),
                ),
                if (profile.email != null && profile.email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.email!,
                    style: TextStyle(color: CMColors.hint, fontSize: 14),
                  ),
                ],
                if (actions != null) ...[const SizedBox(height: 22), actions!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill action button used in the profile card's action row (Edit/Share).
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? CMColors.primaryVariant : CMColors.hint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: CMColors.primaryVariant.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fg.withValues(alpha: enabled ? 0.12 : 0.08),
                ),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? CMColors.text : CMColors.hint,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  final String token;
  final String profileId;
  final String currentUserId;

  const UserProfileScreen({
    super.key,
    required this.token,
    required this.profileId,
    required this.currentUserId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserService userService;
  final userSocket = UserSocketService.instance;
  late Future<User> _userFuture;
  User? _user; // kept locally so we can patch contactStatus in place
  bool isVideoCall = true;
  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    _userFuture = _fetchUser();
  }

  Future<User> _fetchUser() async {
    final user = await userService.getUserById(widget.profileId);
    _user = user;
    return user;
  }

  void _showError(Object e) {
    if (!mounted) return;
    final message = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _runContactAction(
    Future<void> Function() action,
    ContactStatus optimisticStatus,
  ) async {
    if (_user == null || _actionInFlight) return;
    final previous = _user!.contactStatus;
    setState(() {
      _actionInFlight = true;
      _user = _user!.copyWith(contactStatus: optimisticStatus);
    });
    try {
      await action();
    } catch (e) {
      setState(() => _user = _user!.copyWith(contactStatus: previous));
      _showError(e);
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  void _sendFriendRequest() => _runContactAction(
    () => userService.addContact(_user!.id),
    ContactStatus.pendingSent,
  );

  void _acceptFriendRequest() => _runContactAction(
    () => userService.acceptContact(_user!.id),
    ContactStatus.accepted,
  );

  void _declineFriendRequest() => _runContactAction(
    () => userService.declineContact(_user!.id),
    ContactStatus.none,
  );

  void _removeContact() => _runContactAction(
    () => userService.removeContact(_user!.id),
    ContactStatus.none,
  );

  void _startChat() {
    final user = _user;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          currentUserId: widget.currentUserId,
          otherUser: user,
          userSocket: userSocket,
        ),
      ),
    );
  }

  void _startCall({required String callType}) {
    final user = _user;
    if (user == null) return;
    final roomId = '${widget.currentUserId}-${user.id}';
    setState(() => isVideoCall = callType == 'video');

    userSocket.sendCallInvite(user.id, roomId, callType: callType);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CallScreen(
          token: widget.token,
          roomId: roomId,
          userSocket: userSocket,
          callType: callType,
          otherUser: user,
          isCaller: true,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Messaging/calling require an accepted friendship (enforced
  /// server-side too — see AreFriends in signaling/users.go), so the
  /// actions shown here change entirely based on [ContactStatus].
  Widget _buildActions(ContactStatus status) {
    switch (status) {
      case ContactStatus.none:
        return ProfileActionButton(
          icon: PhosphorIconsBold.userPlus,
          label: 'Add Friend',
          onTap: _sendFriendRequest,
        );

      case ContactStatus.pendingSent:
        return ProfileActionButton(
          icon: PhosphorIconsBold.clockCountdown,
          label: 'Request Sent',
          enabled: false,
          onTap: () {},
        );

      case ContactStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: ProfileActionButton(
                icon: PhosphorIconsBold.check,
                label: 'Accept',
                onTap: _acceptFriendRequest,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileActionButton(
                icon: PhosphorIconsBold.x,
                label: 'Decline',
                onTap: _declineFriendRequest,
              ),
            ),
          ],
        );

      case ContactStatus.accepted:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ProfileActionButton(
                    icon: PhosphorIconsBold.chatCircleText,
                    label: 'Message',
                    onTap: _startChat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProfileActionButton(
                    icon: PhosphorIconsBold.userMinus,
                    label: 'Remove',
                    onTap: _removeContact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ProfileActionButton(
                    icon: PhosphorIconsFill.phone,
                    label: 'Voice Call',
                    onTap: () => _startCall(callType: 'audio'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProfileActionButton(
                    icon: PhosphorIconsFill.videoCamera,
                    label: 'Video Call',
                    onTap: () => _startCall(callType: 'video'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMScaffold(
      backgroundImage: 'lib/assets/images/onboarding_background.jpg',
      floatingAppBar: CMFloatingAppBar(
        isTransparent: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.caretLeft,
              color: CMColors.text,
              size: 18,
            ),
          ),
        ),
        title: Center(
          child: Text(
            'Profile',
            style: CMTextStyle.subtitle.copyWith(color: CMColors.text),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FutureBuilder<User>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('⚠️ ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('User not found'));
                }

                final profile = _user!;
                return UserProfile(
                  profile: profile,
                  actions: _buildActions(profile.contactStatus),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
