import 'dart:developer';

import 'package:chatmunication/features/call/call_background.dart';
import 'package:chatmunication/features/call/call_manager.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/signaling/signaling.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  // UI state
  bool _isLocalSmall = true;
  Offset _pipOffset = const Offset(20, 60);

  bool get _isVideo => widget.callType == 'video';

  @override
  void initState() {
    super.initState();

    final mgr = CallManager.instance;
    if (!mgr.isActiveFor(widget.roomId)) {
      // Fresh call — not resuming from the minimized return-to-call banner.
      mgr.begin(
        token: widget.token,
        roomId: widget.roomId,
        userSocket: widget.userSocket,
        callType: widget.callType,
        otherUser: widget.otherUser,
        isCaller: widget.isCaller,
      );
      mgr.start();
    }
    mgr.peerLeftListener = _handlePeerLeft;

    // Register onCallRejected listener
    widget.userSocket.onCallRejected = () {
      log("Call was rejected");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.otherUser?.username ?? "They"} declined the call',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      CallManager.instance.endCall();
    };
  }

  void _handlePeerLeft() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Other user disconnected'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
    CallManager.instance.endCall();
  }

  void _switchViews() {
    setState(() => _isLocalSmall = !_isLocalSmall);
  }

  /// Leaves the call screen without hanging up — the call keeps running
  /// in [CallManager] and a "tap to return to call" banner takes over.
  void _minimizeCall() {
    CallManager.instance.minimize();
    Navigator.of(context).pop();
  }

  void _endCall() {
    final mgr = CallManager.instance;
    if (mgr.signaling?.remoteStreamReady.value == false && widget.isCaller) {
      widget.userSocket.cancelCall(widget.otherUser?.id ?? '', widget.roomId);
    }
    Navigator.pop(context);
    mgr.endCall();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _statusText(bool connected, Duration duration) {
    if (connected) return _formatDuration(duration);
    if (!widget.isCaller) return 'Connecting...';
    final label = _isVideo ? 'Video Calling' : 'Audio Calling';
    return '$label ${widget.otherUser?.username ?? ''}...';
  }

  @override
  void dispose() {
    // Whatever just happened — minimized, ended, or peer left — this
    // screen is no longer around to react to a disconnect.
    CallManager.instance.peerLeftListener = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mgr = CallManager.instance;
    final signaling = mgr.signaling;
    if (signaling == null) {
      // Call already ended via another path (e.g. race with a pop); this
      // screen is about to be removed from the tree.
      return const SizedBox.shrink();
    }

    final local = _isVideo
        ? RTCVideoView(
            signaling.localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : const SizedBox.shrink();

    final remote = _isVideo
        ? RTCVideoView(
            signaling.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : const SizedBox.shrink();

    final bigView = _isLocalSmall ? remote : local;
    final pipView = _isLocalSmall ? local : remote;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimizeCall();
      },
      child: Scaffold(
        backgroundColor: _isVideo ? Colors.black : CMColors.background,
        body: Stack(
          children: [
            if (!_isVideo) const CallGradientBackground(),

            if (_isVideo)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: ValueListenableBuilder<bool>(
                  key: ValueKey(signaling.remoteStreamReady.value),
                  valueListenable: signaling.remoteStreamReady,
                  builder: (context, remoteReady, _) {
                    if (!remoteReady) {
                      // Phase 1: Call not yet accepted — show local preview.
                      return ValueListenableBuilder<bool>(
                        valueListenable: signaling.localStreamReady,
                        builder: (context, ready, _) {
                          return ready
                              ? Positioned.fill(child: local)
                              : const Center(
                                  child: CircularProgressIndicator(),
                                );
                        },
                      );
                    }
                    // Phase 2: Call accepted.
                    return GestureDetector(onTap: _switchViews, child: bigView);
                  },
                ),
              )
            else
              _buildAudioCenter(),

            if (_isVideo)
              IgnorePointer(
                child: Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (_isVideo)
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

                            final snappedX = x < midX
                                ? 20
                                : screenSize.width - pipWidth - 20;

                            final snappedY = y < midY
                                ? topPadding
                                : screenSize.height - pipHeight - bottomPadding;

                            setState(() {
                              _pipOffset = Offset(
                                snappedX.toDouble(),
                                snappedY,
                              );
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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

            _buildTopBar(signaling),
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  // ----- Center content (audio calls) -----

  Widget _buildAudioCenter() {
    final signaling = CallManager.instance.signaling!;
    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RippleAvatar(
              username: widget.otherUser?.username ?? '',
              profilePicture: widget.otherUser?.profilePicture ?? '',
              email: widget.otherUser?.email ?? '',
              size: 160,
            ),
            const SizedBox(height: 28),
            Text(
              widget.otherUser?.username ?? '',
              style: CMTextStyle.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: signaling.remoteStreamReady,
              builder: (context, connected, _) =>
                  ValueListenableBuilder<Duration>(
                    valueListenable: CallManager.instance.callDuration,
                    builder: (context, duration, _) => Text(
                      _statusText(connected, duration),
                      style: CMTextStyle.subtitle.copyWith(
                        color: CMColors.hint,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Top bar -----

  Widget _buildTopBar(Signaling signaling) {
    final glassBg = _isVideo
        ? Colors.black.withValues(alpha: .25)
        : Colors.white.withValues(alpha: .55);
    final glassFg = _isVideo ? Colors.white : CMColors.primaryVariant;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _glassButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: _minimizeCall,
                background: glassBg,
                foreground: glassFg,
              ),
              const SizedBox(width: 12),
              if (_isVideo)
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: signaling.remoteStreamReady,
                    builder: (context, connected, _) =>
                        ValueListenableBuilder<Duration>(
                          valueListenable: CallManager.instance.callDuration,
                          builder: (context, duration, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.otherUser?.username ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _statusText(connected, duration),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                )
              else
                const Spacer(),
              if (_isVideo) ...[
                _glassButton(
                  icon: Icons.cameraswitch_rounded,
                  onTap: () {},
                  background: glassBg,
                  foreground: glassFg,
                ),
                const SizedBox(width: 10),
              ],
              _glassButton(
                icon: Icons.more_horiz,
                onTap: () {},
                background: glassBg,
                foreground: glassFg,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color background,
    required Color foreground,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: background),
        child: Icon(icon, color: foreground, size: 20),
      ),
    );
  }

  // ----- Bottom control bar -----

  Widget _buildControlBar() {
    final labelColor = _isVideo ? Colors.white : CMColors.text;
    final pillColor = _isVideo
        ? Colors.black.withValues(alpha: .25)
        : Colors.white.withValues(alpha: .5);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 32,
      child: SafeArea(
        top: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _controlItem(
                  icon: Icons.volume_up_rounded,
                  label: 'Speaker',
                  bg: Colors.white,
                  fg: CMColors.primaryVariant,
                  labelColor: labelColor,
                  onTap: () {},
                ),
                const SizedBox(width: 22),
                ValueListenableBuilder<bool>(
                  valueListenable: CallManager.instance.isMuted,
                  builder: (context, muted, _) => _controlItem(
                    icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: 'Mute',
                    bg: Colors.white,
                    fg: CMColors.primaryVariant,
                    labelColor: labelColor,
                    onTap: CallManager.instance.toggleMute,
                  ),
                ),
                const SizedBox(width: 22),
                _controlItem(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  bg: Colors.white,
                  fg: CMColors.primaryVariant,
                  labelColor: labelColor,
                  onTap: () {},
                ),
                const SizedBox(width: 22),
                _controlItem(
                  icon: Icons.call_end_rounded,
                  label: 'End',
                  bg: Colors.red,
                  fg: Colors.white,
                  labelColor: labelColor,
                  onTap: _endCall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlItem({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
