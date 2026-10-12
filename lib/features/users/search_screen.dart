import 'dart:async';

import 'package:chatmunication/features/users/profile_widget.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:chatmunication/features/users/widgets/chat_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Dedicated "find people" screen. Tapping a result always opens their
/// profile first — adding as a contact, messaging, and calling all happen
/// from there, never inline from the search row.
class SearchScreen extends StatefulWidget {
  final String token;
  final String currentUserId;

  const SearchScreen({
    super.key,
    required this.token,
    required this.currentUserId,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<User> _results = [];
  bool _loading = false;
  Object? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await UserService(token: widget.token)
          .searchUsers(trimmed);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProfile(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          token: widget.token,
          profileId: user.id,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
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
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            height: 44,
            child: CMTextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
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
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(hasScrollBody: true, child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Search for people by username or email',
            textAlign: TextAlign.center,
            style: TextStyle(color: CMColors.hint),
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(
        child: SpinKitWave(color: CMColors.primaryVariant, size: 30),
      );
    }
    if (_error != null) {
      return Center(child: Text('⚠️ $_error'));
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: CMColors.hint)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        return ChatListTile(
          username: user.username,
          email: user.email ?? '',
          profilePicture: user.profilePicture,
          isSearchResult: true,
          onTap: () => _openProfile(user),
        );
      },
    );
  }
}
