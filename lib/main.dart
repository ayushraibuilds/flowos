import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'data/local/database/app_database.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/themes/models/flow_theme.dart';
import 'presentation/navigation/app_router.dart';
import 'features/notifications/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();

  // Initialize Supabase (skip if not configured — local-first mode)
  // Load SharedPreferences earlier
  final prefs = await SharedPreferences.getInstance();

  // Initialize unique device ID
  await SupabaseConfig.initializeDeviceId(prefs);

  // Initialize Supabase (skip if not configured — local-first mode)
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
  } else {
    debugPrint('⚠️ Supabase not configured — running in local-only mode.');
    debugPrint('   Run with: flutter run --dart-define-from-file=.env');
  }

  onboardingComplete = true;
  if (prefs.getBool('flowos_onboarding_complete') != true) {
    await prefs.setBool('flowos_onboarding_complete', true);
  }

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

class FlowOSApp extends ConsumerWidget {
  const FlowOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    // Dynamically update AppColors
    AppColors.updateTheme(currentTheme);

    return MaterialApp.router(
      title: 'FlowOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
