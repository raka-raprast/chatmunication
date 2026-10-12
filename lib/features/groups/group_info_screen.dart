import 'dart:async';

import 'package:chatmunication/features/groups/group.dart';
import 'package:chatmunication/features/groups/group_service.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Member list + management for a group: add from contacts, remove
/// (creator only, enforced server-side), or leave. Popping this screen
/// with `true` tells `GroupChatScreen` the current user just left, so it
/// should pop itself back to the chat list too.
class GroupInfoScreen extends StatefulWidget {
  final String currentUserId;
  final Group group;
  final UserSocketService userSocket;

  const GroupInfoScreen({
    super.key,
    required this.currentUserId,
    required this.group,
    required this.userSocket,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late GroupService _service;
  late Future<List<GroupMember>> _membersFuture;
  late Future<List<User>> _pendingInvitesFuture;

  @override
  void initState() {
    super.initState();
    _service = GroupService(token: widget.userSocket.token);
    _membersFuture = _service.getGroupMembers(widget.group.id);
    _pendingInvitesFuture = _service.getPendingInvitees(widget.group.id);
    widget.userSocket.addGroupMemberJoinedListener(_handleMemberJoined);
  }

  @override
  void dispose() {
    widget.userSocket.removeGroupMemberJoinedListener(_handleMemberJoined);
    super.dispose();
  }

  void _handleMemberJoined(
    String groupId,
    String userId,
    String username,
    String profilePicture,
    bool isContact,
    int memberCount,
    String content,
    String timestamp,
  ) {
    if (groupId != widget.group.id || !mounted) return;
    _reloadMembers();
  }

  void _reloadMembers() {
    setState(() {
      _membersFuture = _service.getGroupMembers(widget.group.id);
      _pendingInvitesFuture = _service.getPendingInvitees(widget.group.id);
    });
  }

  Future<void> _removeMember(GroupMember member) async {
    try {
      await _service.removeMember(widget.group.id, member.id);
      if (member.id == widget.currentUserId) {
        if (!mounted) return;
        Navigator.pop(context, true); // tells GroupChatScreen we left
        return;
      }
      _reloadMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            member.id == widget.currentUserId
                ? "Failed to leave group"
                : "Failed to remove member",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmRemove(GroupMember member, bool isSelf) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSelf ? 'Leave group?' : 'Remove ${member.username}?'),
        content: Text(
          isSelf
              ? 'You will no longer receive messages from "${widget.group.name}".'
              : '${member.username} will be removed from "${widget.group.name}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isSelf ? 'Leave' : 'Remove',
              style: const TextStyle(color: CMColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _removeMember(member);
  }

  Future<void> _openAddMembers() async {
    final existingMembers = await _membersFuture;
    final existingIds = existingMembers.map((m) => m.id).toSet();
    if (!mounted) return;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMembersSheet(
        token: widget.userSocket.token,
        groupId: widget.group.id,
        existingMemberIds: existingIds,
      ),
    );

    if (added == true) _reloadMembers();
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
        title: const Center(child: Text('Group Info')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  CMAvatar(
                    size: 84,
                    profilePicture: widget.group.picture,
                    email: '',
                    username: widget.group.name,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.group.name,
                    style: CMTextStyle.title.copyWith(
                      color: CMColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members',
                    style: CMTextStyle.small.copyWith(color: CMColors.hint),
                  ),
                  TextButton.icon(
                    onPressed: _openAddMembers,
                    icon: const Icon(
                      PhosphorIconsBold.userPlus,
                      size: 16,
                      color: CMColors.primaryVariant,
                    ),
                    label: const Text(
                      'Add',
                      style: TextStyle(color: CMColors.primaryVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<GroupMember>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: SpinKitWave(
                        color: CMColors.primaryVariant,
                        size: 30,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('⚠️ Failed to load members')),
                  );
                }
                final members = snapshot.data ?? [];
                final amCreator = members.any(
                  (m) => m.id == widget.currentUserId && m.isCreator,
                );
                return Column(
                  children: members.map((m) {
                    final isSelf = m.id == widget.currentUserId;
                    final canRemove = isSelf || amCreator;
                    return ListTile(
                      leading: CMAvatar(
                        profilePicture: m.profilePicture,
                        email: '',
                        username: m.username,
                        size: 40,
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              isSelf ? '${m.username} (You)' : m.username,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!isSelf && !m.isContact) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              PhosphorIconsBold.userCircleMinus,
                              size: 14,
                              color: CMColors.hint,
                            ),
                          ],
                        ],
                      ),
                      subtitle: m.isCreator
                          ? const Text(
                              'Creator',
                              style: TextStyle(color: CMColors.primaryVariant),
                            )
                          : null,
                      trailing: canRemove
                          ? IconButton(
                              icon: Icon(
                                isSelf
                                    ? PhosphorIconsBold.signOut
                                    : PhosphorIconsBold.userMinus,
                                color: CMColors.error,
                                size: 20,
                              ),
                              onPressed: () => _confirmRemove(m, isSelf),
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<User>>(
              future: _pendingInvitesFuture,
              builder: (context, snapshot) {
                final pending = snapshot.data ?? [];
                if (pending.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Invited · awaiting response',
                        style: CMTextStyle.small.copyWith(
                          color: CMColors.hint,
                        ),
                      ),
                    ),
                    ...pending.map(
                      (u) => ListTile(
                        leading: Opacity(
                          opacity: 0.5,
                          child: CMAvatar(
                            profilePicture: u.profilePicture,
                            email: u.email ?? '',
                            username: u.username,
                            size: 40,
                          ),
                        ),
                        title: Text(
                          u.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CMColors.hint,
                          ),
                        ),
                        trailing: const Icon(
                          PhosphorIconsRegular.clock,
                          color: CMColors.hint,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// Bottom sheet for picking contacts not already in the group to add.
class _AddMembersSheet extends StatefulWidget {
  final String token;
  final String groupId;
  final Set<String> existingMemberIds;

  const _AddMembersSheet({
    required this.token,
    required this.groupId,
    required this.existingMemberIds,
  });

  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  late Future<List<UserWithLastMessage>> _contactsFuture;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  List<User> _searchResults = [];
  bool _searching = false;
  Object? _searchError;
  Timer? _debounce;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _contactsFuture = UserService(token: widget.token)
        .getUsersWithLastMessage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(trimmed),
    );
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await UserService(token: widget.token).searchUsers(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e;
        _searching = false;
      });
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await GroupService(token: widget.token)
          .addMembers(widget.groupId, _selectedIds.toList());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add members'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _memberTile({
    required String id,
    required String username,
    required String email,
    required String profilePicture,
    required ScrollController scrollController,
  }) {
    final selected = _selectedIds.contains(id);
    return ListTile(
      onTap: () => _toggle(id),
      leading: CMAvatar(
        profilePicture: profilePicture,
        email: email,
        username: username,
        size: 36,
      ),
      title: Text(username),
      trailing: Checkbox(
        value: selected,
        activeColor: CMColors.primaryVariant,
        onChanged: (_) => _toggle(id),
      ),
    );
  }

  Widget _buildContactsList(ScrollController scrollController) {
    return FutureBuilder<List<UserWithLastMessage>>(
      future: _contactsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitWave(color: CMColors.primaryVariant, size: 30),
          );
        }
        final contacts = (snapshot.data ?? [])
            .where((c) => !widget.existingMemberIds.contains(c.id))
            .toList();
        if (contacts.isEmpty) {
          return const Center(
            child: Text(
              'Everyone in your contacts is already here — search above to invite someone else.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CMColors.hint),
            ),
          );
        }
        return ListView.builder(
          controller: scrollController,
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final c = contacts[index];
            return _memberTile(
              id: c.id,
              username: c.username,
              email: c.email ?? '',
              profilePicture: c.profilePicture,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    if (_searching) {
      return const Center(
        child: SpinKitWave(color: CMColors.primaryVariant, size: 30),
      );
    }
    if (_searchError != null) {
      return const Center(child: Text('⚠️ Search failed'));
    }
    final results = _searchResults
        .where((u) => !widget.existingMemberIds.contains(u.id))
        .toList();
    if (results.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: CMColors.hint)),
      );
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final u = results[index];
        return _memberTile(
          id: u.id,
          username: u.username,
          email: u.email ?? '',
          profilePicture: u.profilePicture,
          scrollController: scrollController,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CMColors.hint.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add members',
                      style: CMTextStyle.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedIds.isEmpty || _submitting
                          ? null
                          : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Invite (${_selectedIds.length})'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: CMTextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  radius: 999,
                  label: 'Search by username or email',
                  prefix: const Icon(
                    PhosphorIconsBold.magnifyingGlass,
                    color: CMColors.primaryVariant,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: _searchController.text.trim().isNotEmpty
                    ? _buildSearchResults(scrollController)
                    : _buildContactsList(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
}
