import 'package:chatmunication/features/groups/group_service.dart';
import 'package:chatmunication/features/groups/group.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Inbox for everything awaiting the user's decision: incoming friend
/// requests and pending group invites. Reached from the chat list's bell
/// icon — the bell's badge count mirrors this screen's combined total.
class RequestsScreen extends StatefulWidget {
  final String token;

  const RequestsScreen({super.key, required this.token});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late final UserService _userService;
  late final GroupService _groupService;

  List<User>? _friendRequests;
  List<GroupInvite>? _groupInvites;
  Object? _error;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _userService = UserService(token: widget.token);
    _groupService = GroupService(token: widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        _userService.getIncomingContactRequests(),
        _groupService.getGroupInvites(),
      ]);
      if (!mounted) return;
      setState(() {
        _friendRequests = results[0] as List<User>;
        _groupInvites = results[1] as List<GroupInvite>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _respondToFriendRequest(
    User user, {
    required bool accept,
  }) async {
    setState(() => _busyIds.add(user.id));
    try {
      if (accept) {
        await _userService.acceptContact(user.id);
      } else {
        await _userService.declineContact(user.id);
      }
      if (!mounted) return;
      setState(() {
        _friendRequests = _friendRequests!
            .where((u) => u.id != user.id)
            .toList();
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(user.id));
    }
  }

  Future<void> _respondToGroupInvite(
    GroupInvite invite, {
    required bool accept,
  }) async {
    setState(() => _busyIds.add(invite.inviteId));
    try {
      if (accept) {
        await _groupService.acceptGroupInvite(invite.inviteId);
      } else {
        await _groupService.declineGroupInvite(invite.inviteId);
      }
      if (!mounted) return;
      setState(() {
        _groupInvites = _groupInvites!
            .where((i) => i.inviteId != invite.inviteId)
            .toList();
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(invite.inviteId));
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
        title: const Center(child: Text('Requests')),
      ),
      body: CustomScrollView(
        slivers: [SliverToBoxAdapter(child: _buildBody())],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text('⚠️ $_error')),
      );
    }
    if (_friendRequests == null || _groupInvites == null) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: SpinKitWave(color: CMColors.primaryVariant, size: 30),
        ),
      );
    }
    if (_friendRequests!.isEmpty && _groupInvites!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Text(
            "You're all caught up — no pending requests.",
            textAlign: TextAlign.center,
            style: TextStyle(color: CMColors.hint),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_friendRequests!.isNotEmpty) ...[
            _sectionLabel('Friend Requests'),
            ..._friendRequests!.map(_buildFriendRequestTile),
          ],
          if (_groupInvites!.isNotEmpty) ...[
            _sectionLabel('Group Invites'),
            ..._groupInvites!.map(_buildGroupInviteTile),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      label,
      style: CMTextStyle.small.copyWith(
        color: CMColors.hint,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _buildFriendRequestTile(User user) {
    final busy = _busyIds.contains(user.id);
    return ListTile(
      leading: CMAvatar(
        profilePicture: user.profilePicture,
        email: user.email ?? '',
        username: user.username,
        size: 44,
      ),
      title: Text(
        user.username,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('wants to be friends'),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleIconButton(
                  icon: PhosphorIconsBold.check,
                  color: CMColors.primaryVariant,
                  onTap: () => _respondToFriendRequest(user, accept: true),
                ),
                const SizedBox(width: 8),
                _circleIconButton(
                  icon: PhosphorIconsBold.x,
                  color: CMColors.error,
                  onTap: () => _respondToFriendRequest(user, accept: false),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupInviteTile(GroupInvite invite) {
    final busy = _busyIds.contains(invite.inviteId);
    return ListTile(
      leading: CMAvatar(
        profilePicture: invite.picture,
        email: '',
        username: invite.groupName,
        size: 44,
      ),
      title: Text(
        invite.groupName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('Invited by ${invite.invitedBy}'),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleIconButton(
                  icon: PhosphorIconsBold.check,
                  color: CMColors.primaryVariant,
                  onTap: () => _respondToGroupInvite(invite, accept: true),
                ),
                const SizedBox(width: 8),
                _circleIconButton(
                  icon: PhosphorIconsBold.x,
                  color: CMColors.error,
                  onTap: () => _respondToGroupInvite(invite, accept: false),
                ),
              ],
            ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
