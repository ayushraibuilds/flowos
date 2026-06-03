import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/focus/focus_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/morning_intention/morning_intention_screen.dart';
import '../screens/break_screen/break_screen.dart';

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
    // TODO: Add shutdown ritual, daily report, onboarding routes
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
