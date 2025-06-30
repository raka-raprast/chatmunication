import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
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
    FlutterRingtonePlayer()
        .play(fromAsset: "lib/assets/audio/ringtone.mp3", ios: IosSounds.glass);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CMAvatar(
                  profilePicture: widget.profilePicture,
                  email: '',
                  username: widget.fromName,
                  size: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.callType == 'video'
                      ? 'Incoming Video Call'
                      : 'Incoming Audio Call',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'from ${widget.fromName}',
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.call_end,
                      label: 'Decline',
                      color: Colors.red,
                      onTap: () {
                        _stopRingtone();
                        widget.userSocket
                            .rejectCall(widget.callerId); // ✅ Reject the call
                        Navigator.pop(context); // Close the incoming screen
                      },
                    ),
                    const SizedBox(width: 40),
                    _ActionButton(
                      icon: Icons.call,
                      label: 'Accept',
                      color: Colors.green,
                      onTap: () {
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
                                  profilePicture: widget.profilePicture),
                            ),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
