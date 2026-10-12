import 'dart:async';

import 'package:chatmunication/features/call/call_screen.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/shared/config/app_config.dart';
import 'package:chatmunication/shared/navigation.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/signaling/signaling.dart';
import 'package:chatmunication/signaling/user_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Owns the active call's [Signaling] connection, mute state, and elapsed
/// duration independently of [CallScreen]'s widget lifecycle.
///
/// Leaving the call screen (back button, or navigating elsewhere in the
/// app) must not tear down the WebRTC connection — mirroring WhatsApp,
/// which keeps a call alive and shows a "tap to return to call" bar while
/// you browse the rest of the app. [CallScreen] only ever reads from this
/// singleton and never owns the [Signaling] instance itself, so popping
/// the screen is purely a UI concern.
class CallManager {
  CallManager._();
  static final CallManager instance = CallManager._();

  Signaling? signaling;
  String? roomId;
  String? token;
  String callType = 'audio';
  User? otherUser;
  bool isCaller = false;
  UserSocketService? userSocket;

  MediaStreamTrack? _audioTrack;
  Timer? _timer;

  /// Set by [CallScreen] while mounted so a peer-disconnect can show a
  /// SnackBar and pop the screen. Left null while minimized, in which
  /// case a disconnect just tears the call down silently.
  VoidCallback? peerLeftListener;

  final ValueNotifier<bool> isMinimized = ValueNotifier(false);
  final ValueNotifier<bool> isMuted = ValueNotifier(false);
  final ValueNotifier<Duration> callDuration = ValueNotifier(Duration.zero);

  OverlayEntry? _bannerEntry;

  bool get isVideo => callType == 'video';

  /// True if there's already a live call for this room — i.e. [CallScreen]
  /// is resuming from the minimized banner rather than starting fresh.
  bool isActiveFor(String roomId) => signaling != null && this.roomId == roomId;

  void begin({
    required String token,
    required String roomId,
    required UserSocketService userSocket,
    required String callType,
    User? otherUser,
    bool isCaller = false,
  }) {
    this.token = token;
    this.roomId = roomId;
    this.userSocket = userSocket;
    this.callType = callType;
    this.otherUser = otherUser;
    this.isCaller = isCaller;
    isMuted.value = false;
    callDuration.value = Duration.zero;

    signaling = Signaling(
      serverUrl: AppConfig.wsBaseUrl,
      roomId: roomId,
      token: token,
      callType: callType,
      onPeerDisconnected: _onPeerDisconnected,
    );
    signaling!.remoteStreamReady.addListener(_onRemoteReadyChanged);
  }

  Future<void> start() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw Exception('Camera and microphone permissions are required');
    }

    final s = signaling;
    if (s == null) return;
    await s.initRenderers();
    await s.connect();

    _audioTrack = s.localStream.getAudioTracks().firstOrNull;
  }

  void _onRemoteReadyChanged() {
    if (signaling?.remoteStreamReady.value == true && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        callDuration.value += const Duration(seconds: 1);
      });
    }
  }

  void _onPeerDisconnected() {
    if (peerLeftListener != null) {
      peerLeftListener!();
    } else {
      endCall();
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _audioTrack?.enabled = !isMuted.value;
  }

  /// Hides the call screen behind a persistent "tap to return to call"
  /// banner, keeping the WebRTC connection alive.
  void minimize() {
    if (signaling == null) return;
    isMinimized.value = true;
    _showBanner();
  }

  /// Re-opens [CallScreen] on top of whatever the user navigated to while
  /// minimized, reusing the same live [Signaling] connection.
  void maximize() {
    final s = signaling;
    final u = userSocket;
    if (s == null || u == null) return;
    _hideBanner();
    isMinimized.value = false;
    navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CallScreen(
          token: token ?? '',
          roomId: roomId ?? '',
          userSocket: u,
          callType: callType,
          otherUser: otherUser,
          isCaller: isCaller,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Fully tears the call down: closes the peer connection, cancels the
  /// timer, and hides the return-to-call banner if present.
  void endCall() {
    _timer?.cancel();
    _timer = null;
    signaling?.remoteStreamReady.removeListener(_onRemoteReadyChanged);
    signaling?.dispose();
    signaling = null;
    roomId = null;
    _audioTrack = null;
    peerLeftListener = null;
    isMinimized.value = false;
    _hideBanner();
  }

  void _showBanner() {
    _hideBanner();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _bannerEntry = OverlayEntry(builder: (_) => const _ReturnToCallBanner());
    overlay.insert(_bannerEntry!);
  }

  void _hideBanner() {
    _bannerEntry?.remove();
    _bannerEntry = null;
  }
}

/// Floating pill shown above whatever screen the user navigates to while
/// a call is minimized — tap anywhere on it to return to [CallScreen].
class _ReturnToCallBanner extends StatelessWidget {
  const _ReturnToCallBanner();

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final mgr = CallManager.instance;
    // Every screen in this app uses CMScaffold/CMFloatingAppBar at
    // kToolbarHeight starting right at the safe-area top — placing the
    // banner there too used to sit directly on top of (and swallow taps
    // meant for) each screen's own back button. Push it below instead.
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    return Positioned(
      top: topInset,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: mgr.maximize,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CMColors.primary, CMColors.primaryVariant],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  mgr.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<Duration>(
                  valueListenable: mgr.callDuration,
                  builder: (context, d, _) => Text(
                    _formatDuration(d),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tap to return to call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
