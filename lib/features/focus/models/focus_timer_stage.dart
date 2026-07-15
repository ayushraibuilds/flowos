import 'package:flowos/data/local/tables/focus_sessions_table.dart';

enum FocusTimerPhase { idle, running, paused, completing, completed, stopped }

class FocusTimerState {
  final String sessionId;
  final String? taskId;
  final String? taskTitle;
  final SessionTypeColumn sessionType;
  final FocusTimerPhase phase;
  final int totalSeconds;
  
  // Time keeping fields
  final int elapsedSeconds;
  final int pauseCount;
  final int backgroundCount;
  final DateTime startedAtUtc;
  final DateTime? pausedAtUtc;
  final DateTime? expectedEndTimeUtc;
  
  // Flowtime specialized time keeping fields
  final int accumulatedRunningSeconds;
  final DateTime? lastResumedAtUtc;

  final String selectedSound;
  final String gardenSeedKind;
  final int gardenVariant;
  final String gardenSeedEmoji;

  const FocusTimerState({
    required this.sessionId,
    this.taskId,
    this.taskTitle,
    required this.sessionType,
    required this.phase,
    required this.totalSeconds,
    required this.elapsedSeconds,
    required this.pauseCount,
    required this.backgroundCount,
    required this.startedAtUtc,
    this.pausedAtUtc,
    this.expectedEndTimeUtc,
    required this.accumulatedRunningSeconds,
    this.lastResumedAtUtc,
    required this.selectedSound,
    required this.gardenSeedKind,
    required this.gardenVariant,
    required this.gardenSeedEmoji,
  });

  FocusTimerState copyWith({
    String? sessionId,
    String? taskId,
    String? taskTitle,
    SessionTypeColumn? sessionType,
    FocusTimerPhase? phase,
    int? totalSeconds,
    int? elapsedSeconds,
    int? pauseCount,
    int? backgroundCount,
    DateTime? startedAtUtc,
    DateTime? pausedAtUtc,
    DateTime? expectedEndTimeUtc,
    int? accumulatedRunningSeconds,
    DateTime? lastResumedAtUtc,
    String? selectedSound,
    String? gardenSeedKind,
    int? gardenVariant,
    String? gardenSeedEmoji,
  }) {
    return FocusTimerState(
      sessionId: sessionId ?? this.sessionId,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      sessionType: sessionType ?? this.sessionType,
      phase: phase ?? this.phase,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      pauseCount: pauseCount ?? this.pauseCount,
      backgroundCount: backgroundCount ?? this.backgroundCount,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      pausedAtUtc: pausedAtUtc ?? this.pausedAtUtc,
      expectedEndTimeUtc: expectedEndTimeUtc ?? this.expectedEndTimeUtc,
      accumulatedRunningSeconds: accumulatedRunningSeconds ?? this.accumulatedRunningSeconds,
      lastResumedAtUtc: lastResumedAtUtc ?? this.lastResumedAtUtc,
      selectedSound: selectedSound ?? this.selectedSound,
      gardenSeedKind: gardenSeedKind ?? this.gardenSeedKind,
      gardenVariant: gardenVariant ?? this.gardenVariant,
      gardenSeedEmoji: gardenSeedEmoji ?? this.gardenSeedEmoji,
    );
  }
}
