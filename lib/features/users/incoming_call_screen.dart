import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';

class IncomingCallScreen extends StatelessWidget {
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
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green.shade700,
                  child: ClipOval(
                    child: Image.network(
                      profilePicture,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person,
                            size: 50, color: Colors.white);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Incoming Call',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'from $fromName',
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
                        userSocket.rejectCall(callerId); // ✅ Reject the call
                        Navigator.pop(context); // Close the incoming screen
                      },
                    ),
                    const SizedBox(width: 40),
                    _ActionButton(
                      icon: Icons.call,
                      label: 'Accept',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              token: token,
                              roomId: roomId,
                              userSocket: userSocket,
                              callType: callType,
                            ),
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
