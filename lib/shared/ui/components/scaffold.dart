import 'package:flutter/material.dart';
import 'package:chatmunication/shared/theme/colors.dart';

class CMScaffold extends StatelessWidget {
  const CMScaffold({
    super.key,
    this.floatingAppBar,
    this.body,
    this.useGradientBackground = true,
    this.backgroundImage,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget? floatingAppBar;
  final Widget? body;
  final bool useGradientBackground;
  final String? backgroundImage;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Container(
      color: useGradientBackground ? CMColors.background : Colors.white,
      child: Stack(
        children: [
          if (backgroundImage != null)
            Positioned.fill(
              child: Image.asset(backgroundImage!, fit: BoxFit.cover),
            )
          else if (useGradientBackground)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CMColors.primary.withOpacity(0.1),
                    CMColors.primaryVariant.withOpacity(0.15),
                  ],
                ),
              ),
            ),

          /// Main scrollable content
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: EdgeInsets.only(top: padding.top),
              child: CustomScrollView(
                slivers: [
                  if (floatingAppBar != null)
                    SliverPersistentHeader(
                      delegate: _FloatingAppBarDelegate(
                        child: floatingAppBar!,
                        height: (floatingAppBar is PreferredSizeWidget)
                            ? (floatingAppBar as PreferredSizeWidget)
                                  .preferredSize
                                  .height
                            : kToolbarHeight,
                      ),
                      floating: true,
                    ),
                  if (body != null) _wrapBody(body!),
                ],
              ),
            ),
          ),

          /// Floating Bottom Navigation Bar
          if (bottomNavigationBar != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20, // floating effect
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, -4),
                              ),
                            ],
                          ),
                          child: bottomNavigationBar,
                        ),
                      ),
                      if (floatingActionButton != null) ...[
                        const SizedBox(width: 12),
                        floatingActionButton!,
                      ],
                    ],
                  ),
                ),
              ),
            )
          // Standalone FAB (no bottom nav bar to sit beside) — standard
          // bottom-right placement.
          else if (floatingActionButton != null)
            Positioned(
              right: 20,
              bottom: 20 + padding.bottom,
              child: Material(
                type: MaterialType.transparency,
                child: floatingActionButton!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _wrapBody(Widget body) {
    if (body is ScrollView) {
      return SliverFillRemaining(child: body);
    } else {
      return SliverToBoxAdapter(child: body);
    }
  }
}

class _FloatingAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FloatingAppBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
