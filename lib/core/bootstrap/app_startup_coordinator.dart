import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../features/notifications/services/notification_service.dart';

/// Represents the classification of startup tasks.
enum StartupTaskStage { prerequisites, deferredMaintenance }

/// Startup execution result details.
class StartupResult {
  final bool prerequisitesSuccess;
  final bool deferredSuccess;
  final String? prerequisiteError;
  final String? deferredError;

  const StartupResult({
    required this.prerequisitesSuccess,
    required this.deferredSuccess,
    this.prerequisiteError,
    this.deferredError,
  });
}

/// Startup Coordinator — Classifies required vs post-frame initialization
/// and isolates non-critical maintenance tasks (e.g., local notifications)
/// so that UI rendering is never blocked by deferred plugin operations.
class AppStartupCoordinator {
  /// Executes deferred post-frame maintenance tasks (local notifications, reminders).
  /// Swallows and logs non-fatal failures to preserve local UI functionality.
  static Future<StartupResult> runDeferredMaintenance({
    Future<void> Function()? initializeNotifications,
    Future<void> Function()? scheduleNotifications,
  }) async {
    bool deferredSuccess = true;
    String? deferredError;

    try {
      if (initializeNotifications != null) {
        await initializeNotifications();
      } else {
        await NotificationService.initialize();
      }

      if (scheduleNotifications != null) {
        await scheduleNotifications();
      } else {
        await NotificationService.scheduleEnergyCheckIns();
        await NotificationService.scheduleReportReminder();
        await NotificationService.scheduleWeeklyReview();
        await NotificationService.scheduleStreakWarning();
      }
    } catch (e, st) {
      deferredSuccess = false;
      deferredError = e.toString();
      debugPrint('⚠️ Deferred notification maintenance skipped: $e\n$st');
    }

    return StartupResult(
      prerequisitesSuccess: true,
      deferredSuccess: deferredSuccess,
      deferredError: deferredError,
    );
  }
}
