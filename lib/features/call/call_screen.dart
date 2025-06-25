import 'dart:developer';
import 'dart:io';
import 'package:chatmunication/signaling/signaling.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String token;
  final String roomId;
  final UserSocketService userSocket; // ✅ optional callback
  final String callType;

  const CallScreen({
    required this.token,
    required this.roomId,
    required this.userSocket,
    required this.callType, // ✅ add this
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late Signaling signaling;
  bool _isMuted = false;
  MediaStreamTrack? _audioTrack;

  // UI state
  bool _isLocalSmall = true;
  Offset _pipOffset = const Offset(20, 60);

  @override
  void initState() {
    super.initState();

    signaling = Signaling(
      serverUrl: 'ws://192.168.100.113:2340',
      roomId: widget.roomId,
      token: widget.token,
      callType: widget.callType, // ✅ pass here
      onPeerDisconnected: _handlePeerLeft,
    );

    // Register onCallRejected listener
    widget.userSocket.onCallRejected = () {
      log("Call was rejected");
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Call was rejected")),
      );
    };

    _start();
  }

  void _handlePeerLeft() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Other user disconnected')),
    );

    // Navigate back to AuthScreen or pop this call screen
    Navigator.of(context).pop();
  }

  Future<void> ensurePermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw Exception('Camera and microphone permissions are required');
    }
  }

  Future<void> _start() async {
    await ensurePermissions();
    await signaling.initRenderers();
    await signaling.connect();

    final stream = signaling.localRenderer.srcObject;
    if (stream != null) {
      _audioTrack = stream.getAudioTracks().firstOrNull;
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _audioTrack?.enabled = !_isMuted;
  }

  void _switchViews() {
    setState(() => _isLocalSmall = !_isLocalSmall);
  }

  @override
  void dispose() {
    signaling.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final local = widget.callType == 'video'
        ? RTCVideoView(signaling.localRenderer, mirror: false)
        : const Center(child: Icon(Icons.mic, size: 64, color: Colors.white));

    final remote = widget.callType == 'video'
        ? RTCVideoView(signaling.remoteRenderer)
        : const Center(
            child: Icon(Icons.person, size: 120, color: Colors.grey));

    final bigView = _isLocalSmall ? remote : local;
    final pipView = _isLocalSmall ? local : remote;

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen area
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: ValueListenableBuilder<bool>(
              key: ValueKey(signaling.remoteStreamReady.value),
              valueListenable: signaling.remoteStreamReady,
              builder: (context, remoteReady, _) {
                if (!remoteReady) {
                  // Phase 1: Call not yet accepted
                  return Stack(
                    children: [
                      if (widget.callType == 'video')
                        ValueListenableBuilder<bool>(
                          valueListenable: signaling.localStreamReady,
                          builder: (context, ready, _) {
                            return ready
                                ? Positioned.fill(child: local)
                                : const Center(
                                    child: CircularProgressIndicator());
                          },
                        )
                      else
                        Positioned.fill(child: local),

                      // ✅ Overlay with calling text
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_in_talk,
                                  size: 64, color: Colors.green),
                              SizedBox(height: 20),
                              Text(
                                'Calling...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Phase 2: Call accepted
                  return GestureDetector(
                    onTap: _switchViews,
                    child: bigView,
                  );
                }
              },
            ),
          ),

          if (widget.callType == 'video')
            ValueListenableBuilder<bool>(
              valueListenable: signaling.remoteStreamReady,
              builder: (context, remoteReady, _) {
                if (!remoteReady) return const SizedBox.shrink();

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  left: _pipOffset.dx,
                  top: _pipOffset.dy,
                  child: GestureDetector(
                    onTap: _switchViews,
                    onPanUpdate: (details) {
                      setState(() {
                        _pipOffset += details.delta;
                      });
                    },
                    onPanEnd: (details) {
                      final screenSize = MediaQuery.of(context).size;
                      const pipWidth = 120.0;
                      const pipHeight = 160.0;

                      final x = _pipOffset.dx;
                      final y = _pipOffset.dy;

                      final midX = screenSize.width / 2;
                      final midY = screenSize.height / 2;

                      final snappedX =
                          x < midX ? 20 : screenSize.width - pipWidth - 20;
                      final snappedY =
                          y < midY ? 60 : screenSize.height - pipHeight - 60;

                      setState(() {
                        _pipOffset =
                            Offset(snappedX.toDouble(), snappedY.toDouble());
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: pipView,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Mute button
          Positioned(
            bottom: 32,
            left: 24,
            child: FloatingActionButton(
              onPressed: _toggleMute,
              backgroundColor: _isMuted ? Colors.red : Colors.green,
              child: Icon(_isMuted ? Icons.mic_off : Icons.mic),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {
                signaling.dispose();
                Navigator.pop(context);
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            ),
          ),
        ],
      ),
    );
  }
}
