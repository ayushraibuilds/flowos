import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// FlowOS navigation — GoRouter with shell for bottom nav.
final appRouter = GoRouter(
  initialLocation: '/home',
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
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FocusScreen(),
          ),
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
  ],
);

/// Bottom navigation shell — persistent across tab screens.
class _AppShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
