import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../presentation/navigation/app_router.dart';

/// Home Widget Data Provider — sends FlowOS data to iOS WidgetKit
/// and Android Jetpack Glance widgets via home_widget package.
///
/// Widget types:
/// - Small: Daily Score (grade + number)
/// - Medium: Daily Score + MITs progress + streak
class HomeWidgetProvider {
  /// App group for iOS (must match WidgetKit configuration)
  static const _appGroupId = 'group.io.flowos.widget';

  /// Android widget class name
  static const _androidClassName = 'FlowOSWidgetProvider';

  /// iOS widget name
  static const _iOSWidgetName = 'FlowOSWidget';

  /// Initialize widget provider
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Update all widget data. Call after:
  /// - Daily score changes
  /// - MITs are completed
  /// - Streak changes
  /// - End of day
  static Future<void> updateWidgetData({
    required int dailyScore,
    required String grade,
    required int mitsCompleted,
    required int mitsTotal,
    required int streakDays,
    required int focusMinutes,
    required int xpToday,
    required int level,
  }) async {
    try {
      // Store data for widget to read
      await Future.wait([
        HomeWidget.saveWidgetData('daily_score', dailyScore),
        HomeWidget.saveWidgetData('grade', grade),
        HomeWidget.saveWidgetData('mits_completed', mitsCompleted),
        HomeWidget.saveWidgetData('mits_total', mitsTotal),
        HomeWidget.saveWidgetData('streak_days', streakDays),
        HomeWidget.saveWidgetData('focus_minutes', focusMinutes),
        HomeWidget.saveWidgetData('xp_today', xpToday),
        HomeWidget.saveWidgetData('level', level),
        HomeWidget.saveWidgetData(
          'last_updated',
          DateTime.now().toIso8601String(),
        ),
      ]);

      // Trigger widget refresh
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidClassName,
      );

      debugPrint('📱 Widget data updated: $grade ($dailyScore)');
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  /// Register widget interaction callback
  static Future<void> registerInteractionCallback(
    Future<void> Function(Uri?) callback,
  ) async {
    HomeWidget.widgetClicked.listen(callback);
  }

  /// Handle widget tap — deep link to appropriate screen
  static Future<void> handleWidgetClick(Uri? uri) async {
    if (uri == null) return;

    // Widget deep links:
    // flowos://daily-report → navigate to daily report
    // flowos://focus → navigate to focus screen
    // flowos://tasks → navigate to tasks
    debugPrint('Widget tapped: $uri');

    final path = uri.path.isNotEmpty ? uri.path : '/${uri.host}';
    final formattedPath = path.startsWith('/') ? path : '/$path';
    debugPrint('Navigating to widget deep link: $formattedPath');
    
    try {
      appRouter.go(formattedPath);
    } catch (e) {
      debugPrint('Deep link navigation failed: $e');
    }
  }

  /// Clear widget data (on logout)
  static Future<void> clearWidgetData() async {
    await Future.wait([
      HomeWidget.saveWidgetData('daily_score', 0),
      HomeWidget.saveWidgetData('grade', '-'),
      HomeWidget.saveWidgetData('mits_completed', 0),
      HomeWidget.saveWidgetData('mits_total', 0),
      HomeWidget.saveWidgetData('streak_days', 0),
      HomeWidget.saveWidgetData('focus_minutes', 0),
      HomeWidget.saveWidgetData('xp_today', 0),
      HomeWidget.saveWidgetData('level', 1),
    ]);

    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidClassName,
    );
  }
}
