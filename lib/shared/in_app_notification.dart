import 'dart:async';
import 'dart:ui';

import 'package:chatmunication/shared/navigation.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/ui/components/avatar.dart';
import 'package:flutter/material.dart';

/// A custom in-app banner — not an OS notification — that slides down from
/// the top of the screen over whatever the user is currently looking at.
/// Used for new-message alerts while the app is in the foreground; the
/// system notification tray is reserved for background/terminated
/// delivery, where there's no app UI to float a banner over.
class InAppNotificationBanner {
  InAppNotificationBanner._();

  static OverlayEntry? _entry;
  static Timer? _dismissTimer;

  static void show({
    required String title,
    required String message,
    required String profilePicture,
    required VoidCallback onTap,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _dismiss();

    final entry = OverlayEntry(
      builder: (context) => _BannerOverlay(
        title: title,
        message: message,
        profilePicture: profilePicture,
        onTap: () {
          onTap();
          _dismiss();
        },
        onSwipeDismiss: _dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _BannerOverlay extends StatefulWidget {
  const _BannerOverlay({
    required this.title,
    required this.message,
    required this.profilePicture,
    required this.onTap,
    required this.onSwipeDismiss,
  });

  final String title;
  final String message;
  final String profilePicture;
  final VoidCallback onTap;
  final VoidCallback onSwipeDismiss;

  @override
  State<_BannerOverlay> createState() => _BannerOverlayState();
}

class _BannerOverlayState extends State<_BannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, topInset > 0 ? 4 : 12, 12, 0),
              child: Material(
                color: Colors.transparent,
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) => widget.onSwipeDismiss(),
                  child: GestureDetector(
                    onTap: widget.onTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CMAvatar(
                                profilePicture: widget.profilePicture,
                                email: '',
                                username: widget.title,
                                size: 42,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: CMColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.message,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: CMColors.hint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
