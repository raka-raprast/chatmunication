import 'dart:ui';

import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:flutter/material.dart';

/// A single row in a [FloatingActionMenu].
class FloatingMenuAction {
  const FloatingMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
}

/// An iOS-style context menu that pops up anchored to a long-pressed row,
/// instead of a centered [showDialog] that feels visually disconnected
/// from whatever was pressed. Everything except the pressed row's bounds
/// dims and blurs ("spotlight"), and the action list floats directly
/// beside it with a frosted-glass card matching [ChatListTile]'s style.
class FloatingActionMenu {
  FloatingActionMenu._();

  static OverlayEntry? _entry;

  /// Shows the menu anchored to [anchorTopLeft]/[anchorSize] — typically
  /// the long-pressed row's own `RenderBox` bounds in global coordinates.
  static void show({
    required BuildContext context,
    required Offset anchorTopLeft,
    required Size anchorSize,
    required List<FloatingMenuAction> actions,
  }) {
    dismiss();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => _FloatingMenuOverlay(
        anchorTopLeft: anchorTopLeft,
        anchorSize: anchorSize,
        actions: actions,
        onDismiss: dismiss,
      ),
    );
    overlay.insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _FloatingMenuOverlay extends StatefulWidget {
  const _FloatingMenuOverlay({
    required this.anchorTopLeft,
    required this.anchorSize,
    required this.actions,
    required this.onDismiss,
  });

  final Offset anchorTopLeft;
  final Size anchorSize;
  final List<FloatingMenuAction> actions;
  final VoidCallback onDismiss;

  @override
  State<_FloatingMenuOverlay> createState() => _FloatingMenuOverlayState();
}

class _FloatingMenuOverlayState extends State<_FloatingMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );

  void _handleAction(FloatingMenuAction action) {
    widget.onDismiss();
    action.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _estimatedMenuHeight(int count) => count * 48.0 + 18;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tileRect = widget.anchorTopLeft & widget.anchorSize;

    const menuWidth = 220.0;
    const spacing = 10.0;
    final estimatedHeight = _estimatedMenuHeight(widget.actions.length);
    final fitsBelow =
        tileRect.bottom + spacing + estimatedHeight < screenSize.height - 24;

    final menuTop =
        (fitsBelow
                ? tileRect.bottom + spacing
                : tileRect.top - spacing - estimatedHeight)
            .clamp(24.0, screenSize.height - 24.0 - estimatedHeight);

    final menuLeft = tileRect.left.clamp(
      16.0,
      screenSize.width - 16.0 - menuWidth,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDismiss,
                child: ClipPath(
                  clipper: _SpotlightClipper(hole: tileRect, radius: 18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 6 * _fade.value,
                      sigmaY: 6 * _fade.value,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.22 * _fade.value),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: menuLeft,
              top: menuTop,
              width: menuWidth,
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: fitsBelow
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: _MenuCard(
                    actions: widget.actions,
                    onActionTap: _handleAction,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.actions, required this.onActionTap});

  final List<FloatingMenuAction> actions;
  final void Function(FloatingMenuAction) onActionTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: CMColors.primaryVariant.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onActionTap(actions[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            actions[i].icon,
                            size: 19,
                            color: actions[i].color ?? CMColors.primaryVariant,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              actions[i].label,
                              style: CMTextStyle.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: actions[i].color ?? CMColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips to "everything except a rounded-rect hole" — used to blur/dim the
/// whole screen while leaving the long-pressed row showing through sharp,
/// like iOS's context-menu spotlight.
class _SpotlightClipper extends CustomClipper<Path> {
  _SpotlightClipper({required this.hole, required this.radius});

  final Rect hole;
  final double radius;

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cut = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)));
    return Path.combine(PathOperation.difference, full, cut);
  }

  @override
  bool shouldReclip(covariant _SpotlightClipper oldClipper) =>
      oldClipper.hole != hole || oldClipper.radius != radius;
}
