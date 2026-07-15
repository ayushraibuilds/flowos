import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/onboarding/models/user_profile.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import '../../navigation/app_router.dart';
import 'onboarding_welcome_screen.dart';
import 'onboarding_rhythm_screen.dart';
import 'onboarding_connect_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  // Temporary configuration captured from Rhythm screen
  List<String> _goals = const ['Deep work'];
  int _focusMinutes = 25;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skipToHome() async {
    final updated = UserProfile.defaults().copyWith(
      completedOnboardingVersion: 2,
      deviceSetupAcknowledged: true,
      protectedWindowConfigured: false,
    );
    await ref.read(userProfileProvider.notifier).updateProfile(updated);
    await completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _finishOnboarding() async {
    final current = ref.read(userProfileProvider);
    final updated = current.copyWith(
      goals: _goals,
      preferredFocusMinutes: _focusMinutes,
      completedOnboardingVersion: 2,
      deviceSetupAcknowledged: true,
      protectedWindowConfigured: false,
    );
    await ref.read(userProfileProvider.notifier).updateProfile(updated);
    await completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          OnboardingWelcomeScreen(
            onContinue: _nextPage,
            onSkip: _skipToHome,
          ),
          OnboardingRhythmScreen(
            onContinue: (goals, minutes) {
              _goals = goals;
              _focusMinutes = minutes;
              _nextPage();
            },
          ),
          OnboardingConnectScreen(
            onComplete: _finishOnboarding,
          ),
        ],
      ),
    );
  }
}
