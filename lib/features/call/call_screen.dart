import 'dart:developer';
import 'dart:io';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:chatmunication/signaling/signaling.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String token;
  final String roomId;
  final UserSocketService userSocket; // ✅ optional callback
  final String callType;
  final User? otherUser;
  final bool isCaller; // Optional, true if this user initiated the call

  const CallScreen({
    required this.token,
    required this.roomId,
    required this.userSocket,
    required this.callType, // ✅ add this
    this.otherUser,
    this.isCaller = false, // Default to false
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Call was rejected")),
      // );
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

    final stream = signaling.localStream;
    _audioTrack = stream.getAudioTracks().firstOrNull;
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
        ? RTCVideoView(
            signaling.localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : const Center(child: Icon(Icons.mic, size: 64, color: Colors.white));

    final remote = widget.callType == 'video'
        ? RTCVideoView(
            signaling.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : Center(
            child: CMAvatar(
            username: widget.otherUser?.username ?? '',
            profilePicture: widget.otherUser?.profilePicture ?? '',
            email: widget.otherUser?.email ?? '',
            size: MediaQuery.of(context).size.width * .5,
          ));

    final bigView = _isLocalSmall ? remote : local;
    final pipView = _isLocalSmall ? local : remote;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CMColors.primary.withValues(alpha: .2),
                  CMColors.primaryVariant.withValues(alpha: .25),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 20,
            child: SafeArea(
                child: Text(
              widget.otherUser?.username ?? '',
              textAlign: TextAlign.center,
              style: CMTextStyle.title.copyWith(fontWeight: FontWeight.w400),
            )),
          ),
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
                        color: Colors.black.withValues(alpha: .5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_in_talk,
                                  size: 64, color: Colors.green),
                              SizedBox(height: 20),
                              Text(
                                widget.isCaller
                                    ? '${widget.callType == 'video' ? 'Video Calling' : 'Audio Calling'} ${widget.otherUser?.username ?? ''}...'
                                    : 'Connecting...',
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

                return Stack(
                  children: [
                    Positioned(
                      left: _pipOffset.dx,
                      top: _pipOffset.dy,
                      child: GestureDetector(
                        onTap: _switchViews,
                        onPanUpdate: (details) {
                          setState(() {
                            _pipOffset += details.delta;
                          });
                        },
                        onPanEnd: (_) {
                          final screenSize = MediaQuery.of(context).size;
                          const pipWidth = 120.0;
                          const pipHeight = 160.0;
                          const bottomPadding = 120;
                          const topPadding = 60.0;

                          final x = _pipOffset.dx;
                          final y = _pipOffset.dy;

                          final midX = screenSize.width / 2;
                          final midY = screenSize.height / 2;

                          final snappedX =
                              x < midX ? 20 : screenSize.width - pipWidth - 20;

                          final snappedY = y < midY
                              ? topPadding
                              : screenSize.height - pipHeight - bottomPadding;

                          setState(() {
                            _pipOffset = Offset(snappedX.toDouble(), snappedY);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
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
                    ),
                  ],
                );
              },
            ),

          Positioned(
            bottom: 32,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              height: 68,
              decoration: BoxDecoration(color: CMColors.background),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          CMColors.primary.withValues(alpha: .2),
                          CMColors.primaryVariant.withValues(alpha: .25),
                        ]),
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        FloatingActionButton(
                          shape: CircleBorder(),
                          onPressed: () {},
                          backgroundColor: CMColors.primaryVariant,
                          child: Icon(
                            Icons.volume_up,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        FloatingActionButton(
                          shape: CircleBorder(),
                          onPressed: _toggleMute,
                          backgroundColor: CMColors.primaryVariant,
                          child: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        FloatingActionButton(
                          shape: CircleBorder(),
                          onPressed: () {},
                          backgroundColor: CMColors.primaryVariant,
                          child: Icon(
                            CupertinoIcons.video_camera_solid,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        FloatingActionButton(
                          shape: CircleBorder(),
                          onPressed: () {
                            if (!signaling.remoteStreamReady.value &&
                                widget.isCaller) {
                              widget.userSocket.cancelCall(
                                  widget.otherUser?.id ?? '', widget.roomId);
                            }
                            signaling.dispose();
                            Navigator.pop(context);
                          },
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.call,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
