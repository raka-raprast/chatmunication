import 'dart:async';

import 'package:chatmunication/features/groups/group_service.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Members can be picked from existing contacts or found by searching any
/// username/email — unlike 1:1 messaging, a group invite doesn't require
/// an existing friendship, since the invitee can simply decline it.
class CreateGroupScreen extends StatefulWidget {
  final String token;
  final String currentUserId;

  const CreateGroupScreen({
    super.key,
    required this.token,
    required this.currentUserId,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  final Map<String, User> _selectedUsers = {};

  late Future<List<UserWithLastMessage>> _contactsFuture;
  List<User> _searchResults = [];
  bool _searching = false;
  Object? _searchError;
  Timer? _debounce;

  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contactsFuture = UserService(token: widget.token)
        .getUsersWithLastMessage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
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

  void _toggle(User user) {
    setState(() {
      if (_selectedIds.contains(user.id)) {
        _selectedIds.remove(user.id);
        _selectedUsers.remove(user.id);
      } else {
        _selectedIds.add(user.id);
        _selectedUsers[user.id] = user;
      }
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Group name is required');
      return;
    }
    if (_selectedIds.length < 2) {
      setState(() => _error = 'Pick at least 2 people for a group');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final group = await GroupService(token: widget.token)
          .createGroup(name, _selectedIds.toList());
      if (!mounted) return;
      Navigator.pop(context, group);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to create group';
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _nameController.text.trim().isNotEmpty &&
        _selectedIds.length >= 2 &&
        !_creating;

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
        title: const Center(child: Text('New Group')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CMTextField(
                controller: _nameController,
                label: 'Group name',
                radius: 16,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Add members (${_selectedIds.length} selected)',
                style: CMTextStyle.small.copyWith(color: CMColors.hint),
              ),
            ),
          ),
          if (_selectedUsers.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: _selectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _selectedUsers.values.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _toggle(user),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CMAvatar(
                                  profilePicture: user.profilePicture,
                                  email: user.email ?? '',
                                  username: user.username,
                                  size: 48,
                                ),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: CMColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      PhosphorIconsBold.x,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 56,
                              child: Text(
                                user.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: CMTextStyle.small,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
          ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: CMColors.error, fontSize: 13),
                ),
              ),
            ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _searchController.text.trim().isNotEmpty
                ? _buildSearchResults()
                : _buildContactsList(),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: _creating ? null : _createGroup,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: canSubmit
                  ? const [Color(0xFF4C94F7), Color(0xFF3C7FF6)]
                  : [
                      CMColors.hint.withValues(alpha: .5),
                      CMColors.hint.withValues(alpha: .5),
                    ],
            ),
            boxShadow: canSubmit
                ? [
                    BoxShadow(
                      color: CMColors.primaryVariant.withValues(alpha: .35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: _creating
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(
                  PhosphorIconsBold.check,
                  color: Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return FutureBuilder<List<UserWithLastMessage>>(
      future: _contactsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitWave(color: CMColors.primaryVariant, size: 30),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('⚠️ Failed to load contacts'));
        }
        final contacts = snapshot.data ?? [];
        if (contacts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No contacts yet — search above to find people to invite.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CMColors.hint),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final c = contacts[index];
            return _memberTile(
              User(
                id: c.id,
                username: c.username,
                email: c.email,
                profilePicture: c.profilePicture,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(
        child: SpinKitWave(color: CMColors.primaryVariant, size: 30),
      );
    }
    if (_searchError != null) {
      return const Center(child: Text('⚠️ Search failed'));
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: CMColors.hint)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final u = _searchResults[index];
        return _memberTile(u);
      },
    );
  }

  Widget _memberTile(User user) {
    final selected = _selectedIds.contains(user.id);
    return ListTile(
      onTap: () => _toggle(user),
      leading: CMAvatar(
        profilePicture: user.profilePicture,
        email: user.email ?? '',
        username: user.username,
        size: 40,
      ),
      title: Text(
        user.username,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Checkbox(
        value: selected,
        activeColor: CMColors.primaryVariant,
        onChanged: (_) => _toggle(user),
      ),
    );
  }
}
