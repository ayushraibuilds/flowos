import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E14), // AppColors.background0
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: FlowOSApp(),
    ),
  );
}

class FlowOSApp extends StatelessWidget {
  const FlowOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // TODO: Replace with GoRouter in Phase 1
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary placeholder — replaced by GoRouter navigation in Phase 1.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FlowOS',
              style: theme.textTheme.displayLarge?.copyWith(
                color: const Color(0xFF00D68F), // emerald
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'intention → focus → recovery → reflection',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Text(
              '🌱 Phase 0 Complete',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
