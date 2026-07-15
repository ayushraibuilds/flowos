import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/xp_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../features/dashboard/providers/dashboard_providers.dart';
import '../../features/xp/widgets/level_up_overlay.dart';
import '../screens/home/home_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/focus/focus_screen.dart';
import '../screens/focus/focus_ritual_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/morning_intention/morning_intention_screen.dart';
import '../screens/break_screen/break_screen.dart';
import '../screens/scroll_tracker/scroll_tracker_screen.dart';
import '../screens/shutdown/shutdown_screen.dart';
import '../screens/report/daily_report_screen.dart';
import '../screens/report/weekly_review_screen.dart';
import '../screens/brain_dump/brain_dump_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/focus/deep_work_screen.dart';
import '../screens/insights/insights_dashboard_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/permission_center_screen.dart';
import '../screens/flow_garden/garden_screen.dart';
import '../screens/protection/app_picker_screen.dart';
import '../../features/energy/widgets/energy_checkin_sheet.dart';
import '../screens/rest/intentional_rest_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

bool onboardingComplete = false;

class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable() {
    if (SupabaseConfig.isConfigured) {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        notifyListeners();
      });
    }
  }

  void notify() {
    notifyListeners();
  }
}

final routerRefreshListenable = RouterRefreshListenable();

Future<void> completeOnboarding() async {
  onboardingComplete = true;
  routerRefreshListenable.notify();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('flowos_onboarding_complete', true);
}

/// FlowOS navigation — GoRouter with shell for bottom nav.
final appRouter = GoRouter(
  initialLocation: '/home',
  refreshListenable: routerRefreshListenable,
  redirect: (context, state) {
    final goingToOnboarding = state.matchedLocation == '/onboarding';
    final goingToAuth = state.matchedLocation == '/auth';

    // 1. If onboarding is not complete, force onboarding (allow auth page if they need it)
    if (!onboardingComplete) {
      if (!goingToOnboarding && !goingToAuth) {
        return '/onboarding';
      }
      return null;
    }

    // Onboarding complete:
    if (SupabaseConfig.isConfigured) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      if (!isLoggedIn) {
        // Not logged in -> must be on auth screen
        if (!goingToAuth) {
          return '/auth';
        }
        return null;
      } else {
        // Logged in -> if trying to go to auth or onboarding, redirect to home
        if (goingToAuth || goingToOnboarding) {
          return '/home';
        }
        return null;
      }
    } else {
      // Supabase not configured -> skip auth, redirect to home if on auth/onboarding
      if (goingToAuth || goingToOnboarding) {
        return '/home';
      }
      return null;
    }
  },
  routes: [
    // ─── Shell route with bottom navigation ───────────────────────
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/tasks',
          name: 'tasks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TasksScreen(),
          ),
        ),
        GoRoute(
          path: '/focus',
          name: 'focus',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return NoTransitionPage(
              child: FocusScreen(
                durationMinutes: extra?['durationMinutes'] as int?,
                sessionLabel: extra?['sessionLabel'] as String?,
                firstSeed: extra?['firstSeed'] as bool? ?? false,
                autoStart: extra?['autoStart'] as bool? ?? false,
              ),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),

    // ─── Full-screen routes (no bottom nav) ──────────────────────
    GoRoute(
      path: '/garden',
      name: 'garden',
      builder: (context, state) => const GardenScreen(),
    ),
    GoRoute(
      path: '/rest',
      name: 'rest',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final minutes = extras?['defaultMinutes'] as int? ?? 5;
        final autoStart = extras?['autoStart'] as bool? ?? false;
        return IntentionalRestScreen(
          defaultMinutes: minutes,
          autoStart: autoStart,
        );
      },
    ),
    GoRoute(
      path: '/morning-intention',
      name: 'morningIntention',
      builder: (context, state) => const MorningIntentionScreen(),
    ),
    GoRoute(
      path: '/break',
      name: 'break',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return BreakScreen(
          xpEarned: extras['xpEarned'] as int? ?? 0,
          qualityGrade: extras['qualityGrade'] as String? ?? 'B',
          focusMinutes: extras['focusMinutes'] as int? ?? 25,
        );
      },
    ),
    GoRoute(
      path: '/scroll-tracker',
      name: 'scrollTracker',
      builder: (context, state) => const ScrollTrackerScreen(),
    ),
    GoRoute(
      path: '/permissions',
      name: 'permissions',
      builder: (context, state) => const PermissionCenterScreen(),
    ),
    GoRoute(
      path: '/focus-ritual',
      name: 'focusRitual',
      builder: (context, state) => FocusRitualScreen(
        onComplete: () => Navigator.pop(context),
      ),
    ),
    GoRoute(
      path: '/shutdown',
      name: 'shutdown',
      builder: (context, state) => const ShutdownRitualScreen(),
    ),
    GoRoute(
      path: '/daily-report',
      name: 'dailyReport',
      builder: (context, state) => const DailyReportScreen(),
    ),
    GoRoute(
      path: '/weekly-review',
      name: 'weeklyReview',
      builder: (context, state) => const WeeklyReviewScreen(),
    ),
    GoRoute(
      path: '/brain-dump',
      name: 'brainDump',
      builder: (context, state) => const BrainDumpScreen(),
    ),

    // ─── Auth & Onboarding ───────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // ─── Phase 5: Deep Work + Insights ──────────────────────────
    GoRoute(
      path: '/deep-work',
      name: 'deepWork',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return DeepWorkScreen(
          taskTitle: extras['taskTitle'] as String?,
          taskId: extras['taskId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/insights',
      name: 'insights',
      builder: (context, state) => const InsightsDashboardScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/app-picker',
      name: 'appPicker',
      builder: (context, state) => const AppPickerScreen(),
    ),
    GoRoute(
      path: '/energy-checkin',
      name: 'energyCheckin',
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.background0,
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: SingleChildScrollView(
                child: EnergyCheckInSheet(),
              ),
            ),
          ),
        ),
      ),
    ),
  ],
);

/// Bottom navigation shell — persistent across tab screens.
class _AppShell extends ConsumerWidget {
  const _AppShell({required this.child});

  final Widget child;

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Home', path: '/home'),
    (icon: Icons.check_circle_outline_rounded, label: 'Tasks', path: '/tasks'),
    (icon: Icons.timer_rounded, label: 'Focus', path: '/focus'),
    (icon: Icons.person_rounded, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for level increases to trigger the level-up celebration overlay
    ref.listen<int>(currentLevelProvider, (prev, next) {
      if (prev != null && next > prev) {
        LevelUpOverlay.show(
          context,
          newLevel: next,
          tierName: XpConstants.tierName(next),
        );
      }
    });

    final currentIndex = _currentIndex(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final isActive = i == currentIndex;
                final tab = _tabs[i];
                return GestureDetector(
                  onTap: () => context.go(tab.path),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          size: 24,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.bottomNavigationBarTheme
                                  .unselectedItemColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w500 : FontWeight.w400,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.bottomNavigationBarTheme
                                    .unselectedItemColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
