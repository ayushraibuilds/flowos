import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'data/local/database/app_database.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';
import 'features/notifications/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();

  // Initialize Supabase (skip if not configured — local-first mode)
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } else {
    debugPrint('⚠️ Supabase not configured — running in local-only mode.');
    debugPrint('   Run with: flutter run --dart-define-from-file=.env');
  }

  // Load onboarding flag and auto-migrate existing dogfood users
  final prefs = await SharedPreferences.getInstance();
  bool onboardingDone = prefs.getBool('flowos_onboarding_complete') ?? false;

  if (!onboardingDone) {
    final db = AppDatabase();
    try {
      final plans = await db.select(db.dailyPlans).get();
      final xp = await db.select(db.xpLedgerEntries).get();
      if (plans.isNotEmpty || xp.isNotEmpty) {
        onboardingDone = true;
        await prefs.setBool('flowos_onboarding_complete', true);
      }
    } catch (e) {
      debugPrint('Error during onboarding check: $e');
    } finally {
      await db.close();
    }
  }

  onboardingComplete = onboardingDone;

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
    return MaterialApp.router(
      title: 'FlowOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
