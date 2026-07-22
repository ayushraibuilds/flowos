import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/focus/providers/nudge_provider.dart';

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/themes/models/flow_theme.dart';
import 'presentation/navigation/app_router.dart';
import 'features/notifications/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and schedule notifications
  await NotificationService.initialize();
  await NotificationService.scheduleEnergyCheckIns();
  await NotificationService.scheduleReportReminder();
  await NotificationService.scheduleWeeklyReview();
  await NotificationService.scheduleStreakWarning();

  // Initialize Supabase (skip if not configured — local-first mode)
  // Load SharedPreferences earlier
  final prefs = await SharedPreferences.getInstance();

  // Check if database exists in documents directory to detect fresh install vs upgrade
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dbFolder.path, 'flowos.sqlite'));
  if (!dbFile.existsSync()) {
    // Fresh install — clear potentially stale SharedPreferences backed up by Android auto-restore
    await prefs.remove('flowos_onboarding_complete');
    await prefs.remove('flowos_user_profile');
    await prefs.remove('flowos_active_session_id');
  }

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

  onboardingComplete = prefs.getBool('flowos_onboarding_complete') ?? false;

  // Set system UI style for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E14), // AppColors.background0
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        options.environment = const String.fromEnvironment(
          'SENTRY_ENV',
          defaultValue: 'development',
        );
      },
      appRunner: () => runApp(
        const ProviderScope(
          child: FlowOSApp(),
        ),
      ),
    );
  } else {
    debugPrint('⚠️ Sentry DSN not configured — crash reporting disabled.');
    debugPrint('   Run with: flutter run --dart-define=SENTRY_DSN=https://...');
    runApp(
      const ProviderScope(
        child: FlowOSApp(),
      ),
    );
  }
}

class FlowOSApp extends ConsumerStatefulWidget {
  const FlowOSApp({super.key});

  @override
  ConsumerState<FlowOSApp> createState() => _FlowOSAppState();
}

class _FlowOSAppState extends ConsumerState<FlowOSApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentNudgeProvider.notifier).checkForNudge();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(currentNudgeProvider.notifier).checkForNudge();
    }
  }

  @override
  Widget build(BuildContext context) {
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
