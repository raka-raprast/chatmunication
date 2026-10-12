import 'package:chatmunication/features/auth/ui/auth_screen.dart';
import 'package:chatmunication/features/onboarding/pages/page_bring_people_closer.dart';
import 'package:chatmunication/features/onboarding/pages/page_realtime_messaging.dart';
import 'package:chatmunication/features/onboarding/pages/page_stay_connected.dart';
import 'package:chatmunication/features/onboarding/pages/page_voice_video_calls.dart';
import 'package:chatmunication/features/onboarding/widgets/onboarding_background.dart';
import 'package:chatmunication/features/onboarding/widgets/onboarding_controls.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key persisted in [SharedPreferences] once the user has completed
/// (or skipped) the onboarding flow, so it is only ever shown once.
const String onboardingCompleteKey = 'onboarding_complete';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    PageStayConnected(),
    PageRealtimeMessaging(),
    PageVoiceVideoCalls(),
    PageBringPeopleCloser(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompleteKey, true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _goToNextPage() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final showSkip = _currentPage != 0 && !isLastPage;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: OnboardingBackground()),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: showSkip
                        ? Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: OnboardingSkipButton(
                              onTap: _finishOnboarding,
                            ),
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: _pages
                        .map(
                          (page) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: page,
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                  child: isLastPage
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OnboardingGetStartedButton(
                              onTap: _finishOnboarding,
                            ),
                            const SizedBox(height: 18),
                            OnboardingPageIndicator(
                              count: _pages.length,
                              current: _currentPage,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OnboardingPageIndicator(
                              count: _pages.length,
                              current: _currentPage,
                            ),
                            OnboardingNextButton(onTap: _goToNextPage),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
