import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/features/users/user_service.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/appbar.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/shared/ui/components/back_button.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  final User profile;

  const UserProfile({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            profile.id,
            style: const TextStyle(color: CMColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            '@${profile.username}',
            style: CMTextStyle.title.copyWith(color: CMColors.text),
          ),
          const SizedBox(height: 8),
          CMAvatar(
            size: 100,
            profilePicture: profile.profilePicture,
            email: profile.email ?? '',
            username: profile.username,
          ),
          const SizedBox(height: 16),
          Text(
            '${profile.email}',
            style: const TextStyle(color: CMColors.text),
          ),
        ],
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  final String token;
  final String profileId;

  const UserProfileScreen({
    super.key,
    required this.token,
    required this.profileId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserService userService;
  late Future<User> _userFuture;
  User? _user; // store locally for isAdded update

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

  void _toggleContact() async {
    if (_user == null) return;

    final isAdded = _user!.isAdded ?? false;

    if (isAdded) {
      await userService.removeContact(_user!.id);
    } else {
      await userService.addContact(_user!.id);
    }

    setState(() {
      _user = _user!
          .copyWith(isAdded: !isAdded); // requires copyWith or manual change
    });
  }

  @override
  Widget build(BuildContext context) {
    return CMScaffold(
      floatingAppBar: CMFloatingAppBar(
        leading: CMBackButton(),
        title: const Center(child: Text("Profile")),
        actions: const [
          Opacity(opacity: 0, child: IgnorePointer(child: CMBackButton()))
        ],
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('⚠️ ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('User not found'));
          }

          final profile = _user!;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UserProfile(profile: profile),
              SizedBox(height: MediaQuery.of(context).size.height * .45),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: profile.isAdded ?? false
                      ? CMColors.error
                      : CMColors.primaryVariant,
                  disabledBackgroundColor: profile.isAdded ?? false
                      ? CMColors.error
                      : CMColors.primaryVariant,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                ),
                onPressed: _toggleContact,
                child: Text(
                  profile.isAdded ?? false ? "Remove" : "Add",
                  style: CMTextStyle.text.copyWith(
                    color: CMColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
