import 'package:chatmunication/features/call/call_background.dart';
import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:permission_handler/permission_handler.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerId;
  final String roomId;
  final String fromName;
  final String token;
  final String profilePicture;
  final String callType;
  final UserSocketService userSocket;

  const IncomingCallScreen({
    super.key,
    required this.callerId,
    required this.roomId,
    required this.token,
    required this.fromName,
    required this.profilePicture, // Optional, can be empty if not provided
    required this.userSocket, // ✅ Required
    this.callType = 'video', // Default to video call
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  @override
  void initState() {
    super.initState();
    ensurePermissions();
    _playRingtone();
    widget.userSocket.onCallCancelled = () {
      if (!mounted) return;
      _stopRingtone();
      Navigator.pop(context);
    };
  }

  Future<void> _playRingtone() async {
    FlutterRingtonePlayer().play(
      fromAsset: "lib/assets/audio/ringtone.mp3",
      ios: IosSounds.glass,
    );
  }

  void _stopRingtone() {
    FlutterRingtonePlayer().stop();
  }

  Future<void> ensurePermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw Exception('Camera and microphone permissions are required');
    }
  }

  @override
  void dispose() {
    _stopRingtone();
    super.dispose();
  }

  void _decline() {
    _stopRingtone();
    widget.userSocket.rejectCall(widget.callerId);
    Navigator.pop(context);
  }

  void _accept() {
    _stopRingtone();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CallScreen(
          token: widget.token,
          roomId: widget.roomId,
          userSocket: widget.userSocket,
          callType: widget.callType,
          isCaller: false,
          otherUser: User(
            id: widget.callerId,
            username: widget.fromName,
            profilePicture: widget.profilePicture,
          ),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CallGradientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RippleAvatar(
                    username: widget.fromName,
                    profilePicture: widget.profilePicture,
                    size: 160,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.callType == 'video'
                        ? 'Incoming Video Call'
                        : 'Incoming Audio Call',
                    style: CMTextStyle.subtitle.copyWith(
                      color: CMColors.hint,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'from ${widget.fromName}',
                    style: CMTextStyle.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 56),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CallActionButton(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        color: Colors.red,
                        onTap: _decline,
                      ),
                      const SizedBox(width: 56),
                      _CallActionButton(
                        icon: Icons.call_rounded,
                        label: 'Accept',
                        color: Colors.green,
                        onTap: _accept,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: CMTextStyle.text.copyWith(
            color: CMColors.hint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
